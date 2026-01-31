# Workspace Boundary Enforcement Implementation

**Date:** January 30, 2026  
**Status:** ✅ Implementation Complete, ⏳ Testing Required  
**Related:** Decision 9 in DECISIONS.md, Phase 1 in PHASE1_IMPLEMENTATION.md

## Summary

Successfully implemented CRDT workspace boundary enforcement to restrict CRDT synchronization to files within `$XDG_DATA_HOME/clearhead/` only. This prevents workspace pollution from project files while maintaining full LSP functionality for all `.actions` files.

## Changes Implemented

### 1. DECISIONS.md
**File:** `DECISIONS.md`  
**Status:** ✅ Complete

**Changes:**
- Added Decision 9: CRDT Workspace Boundary Enforcement (after Decision 6)
- Updated "Last Updated" date to January 30, 2026
- Added to summary table: "CRDT workspace boundary | ✅ Done | Prevents workspace pollution"

**Location:** Lines 120-205

### 2. Workspace Detection (clearhead-cli)
**File:** `clearhead-cli/src/crdt.rs`  
**Status:** ✅ Complete

**Changes:**
- Updated `Workspace::detect()` to validate file location
- Canonicalizes file paths to resolve symlinks
- Returns error if file is outside `$XDG_DATA_HOME/clearhead/`
- Error message clearly states workspace boundary

**Code:**
```rust
pub fn detect(file_path: &Path) -> Result<Self, String> {
    let workspace = Workspace::global()?;
    
    // Canonicalize to resolve symlinks
    let canonical_file = file_path.canonicalize()
        .map_err(|e| format!("Cannot resolve file path '{}': {}", file_path.display(), e))?;
    let canonical_data = workspace.data_dir.canonicalize()
        .unwrap_or_else(|_| workspace.data_dir.clone());
    
    // Validate workspace boundary
    if !canonical_file.starts_with(&canonical_data) {
        return Err(format!(
            "File outside managed workspace (file: {}, workspace: {})",
            canonical_file.display(),
            canonical_data.display()
        ));
    }
    
    Ok(workspace)
}
```

### 3. LSP did_save Handler (clearhead-cli)
**File:** `clearhead-cli/src/lsp.rs`  
**Status:** ✅ Complete

**Changes:**
- Added graceful handling for "outside managed workspace" errors
- Silent skip for non-workspace files (no error diagnostic)
- Workspace files: Full CRDT sync + workspace/applyEdit
- Non-workspace files: LSP features work, no CRDT sync

**Behavior:**
```rust
match ActionRepository::load(path.to_path_buf()) {
    Ok(mut repo) => {
        // Workspace file - full CRDT sync
    }
    Err(e) if e.contains("outside managed workspace") => {
        // Non-workspace file - silent skip
        debug!("Skipping CRDT sync for non-workspace file");
    }
    Err(e) => {
        // Actual error - show diagnostic
    }
}
```

### 4. forceSync Command (clearhead-cli)
**File:** `clearhead-cli/src/lsp.rs`  
**Status:** ✅ Complete

**Changes:**
- Added workspace boundary check in `clearhead/forceSync` command
- Shows warning message for non-workspace files
- Explains where managed workspace is located

**Behavior:**
- Workspace files: Resets buffer to CRDT state
- Non-workspace files: Warning message with workspace location
- CRDT errors: Error message as before

### 5. Neovim force-sync Pattern (clearhead.nvim)
**File:** `clearhead.nvim/fnl/clearhead/init.fnl`  
**Status:** ✅ Complete  
**Compiled:** `lua/clearhead/init.lua` ✅

**Changes:**
- Updated to use `client.request` pattern (matches `archive` command)
- More reliable LSP protocol handling
- Better error reporting

**Before:**
```fennel
(vim.lsp.buf.execute_command {:command "clearhead/forceSync" :arguments [uri]})
```

**After:**
```fennel
(client.request :workspace/executeCommand
                {:command :clearhead/forceSync :arguments [uri]}
                (fn [err result]
                  (when err
                    (vim.notify (.. "Force sync failed: " err.message)
                                vim.log.levels.ERROR))))
```

## Build Status

### clearhead-cli
✅ **Compiled successfully** (release build)
```bash
cargo build --release
# Finished `release` profile [optimized] target(s) in 15.42s
```

### clearhead.nvim
✅ **Fennel compiled to Lua**
```bash
fennel --compile fnl/clearhead/init.fnl > lua/clearhead/init.lua
```

## Testing Checklist

### ⏳ Manual Testing Required

#### Test 1: Workspace File - Full Functionality
```bash
# Setup
mkdir -p ~/.local/share/clearhead
echo "[ ] Workspace task" > ~/.local/share/clearhead/test.actions

# Test in Neovim
nvim ~/.local/share/clearhead/test.actions
:w  # First save

# Expected:
# - UUID added via workspace/applyEdit
# - Buffer shows: [ ] Workspace task #<uuid>
# - Second :w is clean (no file changed error)

# Verify CRDT
stat ~/.local/state/clearhead/workspace.crdt
# Should show recent modification time
```

#### Test 2: Non-Workspace File - Silent Skip
```bash
# Setup
mkdir -p ~/projects/test
echo "[ ] Project task" > ~/projects/test/todo.actions

# Test in Neovim
nvim ~/projects/test/todo.actions
:w  # Save

# Expected:
# - No UUID added (no workspace/applyEdit)
# - File unchanged: [ ] Project task
# - No error messages
# - LSP diagnostics still work (syntax checking, etc.)
```

#### Test 3: ForceSync - Workspace File
```bash
nvim ~/.local/share/clearhead/test.actions
:ClearheadForceSync

# Expected:
# - Buffer replaced with CRDT content
# - Success message: "Buffer synced with CRDT state"
# - No "Unknown command" error
```

#### Test 4: ForceSync - Non-Workspace File
```bash
nvim ~/projects/test/todo.actions
:ClearheadForceSync

# Expected:
# - Warning message: "File is outside managed workspace..."
# - Message explains where workspace is
# - No crash
```

#### Test 5: Symlink Rejection
```bash
# Create symlink
ln -s ~/projects/test/todo.actions ~/.local/share/clearhead/link.actions

nvim ~/.local/share/clearhead/link.actions
:w

# Expected:
# - No CRDT sync (canonicalize resolves to ~/projects/test/todo.actions)
# - Silent skip (same as Test 2)
```

## Installation

To use the updated implementation:

```bash
# Install updated CLI
cd clearhead-cli
cargo install --path .

# Restart Neovim
# (LSP will use new binary automatically)
```

## Success Criteria

- ✅ **Code complete:** All changes implemented
- ✅ **Compiles:** Both CLI and Neovim plugin build successfully
- ⏳ **Workspace files sync:** Full CRDT functionality
- ⏳ **Non-workspace files skip:** Silent, no errors
- ⏳ **ForceSync works:** Both workspace and non-workspace cases
- ⏳ **No regressions:** Existing features continue working

## Rollback Plan

If issues arise:

### Quick Rollback (5 minutes)
```bash
cd clearhead-cli
git revert <commit-hash>
cargo install --path .
```

### Partial Rollback (Disable Validation)
```rust
// In Workspace::detect(), remove validation:
pub fn detect(file_path: &Path) -> Result<Self, String> {
    Ok(Workspace::global()?)  // Skip validation
}
```

## Migration Notes

**No user action required:**
- Existing CRDT data preserved
- Workspace files continue syncing
- Non-workspace files gracefully skip CRDT sync
- No breaking changes

## Related Documentation

- **DECISIONS.md:** Decision 9 (workspace boundary philosophy)
- **PHASE1_IMPLEMENTATION.md:** Phase 1.1 (buffer sync fix)
- **specifications/naming_conventions.md:** Workspace structure

## Next Steps

1. ⏳ **Manual testing** (see Testing Checklist above)
2. ⏳ **Install CLI:** `cargo install --path clearhead-cli`
3. ⏳ **Restart Neovim** to use new LSP binary
4. ⏳ **Verify behavior** with real-world files
5. ⏳ **Report any issues** or unexpected behavior

---

**Implementation completed:** January 30, 2026  
**Ready for:** Manual testing and validation
