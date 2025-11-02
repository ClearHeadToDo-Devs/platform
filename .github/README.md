# GitHub Actions Workflows

This directory contains automated CI/CD workflows for the ClearHead Platform.

## Workflows

### `deploy-vocab.yml` - Vocabulary Deployment Pipeline

Automated validation, testing, and deployment for the Actions Vocabulary ontology.

**Triggers:**
- Push to any branch (with changes in `ontology/**`)
- Pull requests to `main` (with changes in `ontology/**`)

**Jobs:**

1. **validate** - Validates ontology and runs tests
   - Validates TTL syntax
   - Runs SHACL validation
   - Tests example instances
   - Runs on: All pushes and PRs

2. **build-site** - Builds deployment site
   - Generates JSON schemas
   - Builds complete site structure
   - Validates deployment readiness
   - Runs on: All pushes and PRs

3. **deploy-cloudflare** - Deploys to production
   - Uploads site to Cloudflare Pages
   - Updates production URL
   - Runs on: **Push to `main` only**

4. **notify** - Reports deployment status
   - Shows deployment URLs
   - Reports success/failure
   - Runs on: After Cloudflare deployment

**Required Secrets:**
- `CLOUDFLARE_API_TOKEN` - Cloudflare API token with Pages edit permission
- `CLOUDFLARE_ACCOUNT_ID` - Your Cloudflare account ID

**Setup Guide:** See [CLOUDFLARE_SETUP.md](./CLOUDFLARE_SETUP.md)

## Deployment Flow

### Pull Request
```
Push to feature branch
  ↓
Create PR to main
  ↓
✅ Validate ontology
✅ Run tests (SHACL + examples)
✅ Build site
❌ Do NOT deploy
  ↓
Review and merge
```

### Main Branch
```
Merge to main
  ↓
✅ Validate ontology
✅ Run tests
✅ Build site
🚀 Deploy to Cloudflare
  ↓
Live at:
- https://clearhead.us/vocab/actions/v3/
- https://actions-vocabulary.pages.dev
```

## Local Testing

Test the workflow locally before pushing:

```bash
cd ontology

# Run validation (matches CI)
uv run invoke validate

# Run all tests (matches CI)
uv run invoke test
uv run pytest tests/v3/test_example_validation.py -v

# Build site (matches CI)
uv run invoke build-site

# Verify site structure
ls -R site/
```

## Monitoring

**View workflow runs:**
- Repository → Actions tab
- Click on a workflow run to see logs
- Check each job for details

**View deployments:**
- [Cloudflare Dashboard](https://dash.cloudflare.com/)
- Workers & Pages → actions-vocabulary
- See deployment history and logs

## Troubleshooting

### Workflow fails on "validate" job
**Check:**
- TTL syntax errors in ontology files
- SHACL validation failures
- Example validation errors

**Fix:**
```bash
cd ontology
uv run invoke validate  # Check syntax
uv run invoke test      # Check SHACL
```

### Workflow fails on "build-site" job
**Check:**
- Missing dependencies
- Schema generation errors
- Site structure issues

**Fix:**
```bash
cd ontology
uv run invoke build-site  # Test build
ls -R site/               # Check output
```

### Workflow fails on "deploy-cloudflare" job
**Check:**
- GitHub secrets are set correctly
- Cloudflare project exists
- API token has correct permissions

**Fix:**
See [CLOUDFLARE_SETUP.md](./CLOUDFLARE_SETUP.md) for detailed setup

## Adding New Workflows

When adding new workflows:

1. Create `*.yml` file in `.github/workflows/`
2. Use existing workflows as templates
3. Test locally first
4. Document in this README
5. Add required secrets to repository settings

## Security

- Never commit secrets or tokens
- Use GitHub secrets for sensitive data
- Limit workflow permissions
- Review workflow runs regularly
- Rotate API tokens periodically

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Cloudflare Pages Actions](https://github.com/cloudflare/wrangler-action)
- [Workflow Syntax Reference](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
