# Cloudflare Deployment Setup

This guide explains how to configure automated deployment to Cloudflare Pages for the Actions Vocabulary ontology.

## Prerequisites

1. **Cloudflare Account** with Pages enabled
2. **GitHub Repository** with Actions enabled
3. **Cloudflare Pages Project** named `actions-vocabulary`

## Step 1: Create Cloudflare API Token

### Option A: Using Cloudflare Dashboard

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Go to **My Profile** → **API Tokens**
3. Click **Create Token**
4. Use the **Edit Cloudflare Workers** template, or create a custom token with:
   - **Permissions:**
     - `Account` → `Cloudflare Pages` → `Edit`
   - **Account Resources:**
     - Include → Your account
5. Click **Continue to summary** → **Create Token**
6. **Copy the token** (you won't see it again!)

### Option B: Using Wrangler CLI

```bash
# Install wrangler
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Get API token (will be in ~/.wrangler/config/default.toml)
cat ~/.wrangler/config/default.toml
```

## Step 2: Get Cloudflare Account ID

### Option A: From Dashboard

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Select any domain (or go to **Workers & Pages**)
3. Scroll down the right sidebar
4. Copy the **Account ID**

### Option B: Using Wrangler

```bash
wrangler whoami
# Look for "Account ID: ..."
```

## Step 3: Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

### Required Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `CLOUDFLARE_API_TOKEN` | API token from Step 1 | `abc123...` |
| `CLOUDFLARE_ACCOUNT_ID` | Account ID from Step 2 | `1234567890abcdef...` |

### Adding Secrets

```bash
# Via GitHub CLI (if installed)
gh secret set CLOUDFLARE_API_TOKEN
# Paste your token when prompted

gh secret set CLOUDFLARE_ACCOUNT_ID
# Paste your account ID when prompted
```

Or add them manually through the GitHub web interface.

## Step 4: Create Cloudflare Pages Project

### Option A: Using Wrangler CLI

```bash
cd ontology

# Build the site first
uv run invoke build-site

# Create initial deployment (this creates the project)
wrangler pages deploy site --project-name=actions-vocabulary --branch=main
```

### Option B: Using Cloudflare Dashboard

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **Workers & Pages**
3. Click **Create application** → **Pages** → **Upload assets**
4. Name your project: `actions-vocabulary`
5. Upload the `site/` directory
6. Click **Save and Deploy**

## Step 5: Configure Custom Domain (Optional)

If you want to use `clearhead.us` instead of `actions-vocabulary.pages.dev`:

1. Go to **Workers & Pages** → **actions-vocabulary**
2. Click **Custom domains** tab
3. Click **Set up a custom domain**
4. Enter: `clearhead.us`
5. Follow DNS configuration instructions

The workflow will automatically deploy to both:
- `https://actions-vocabulary.pages.dev`
- `https://clearhead.us` (if custom domain is configured)

## Step 6: Test the Deployment

### Manual Deployment Test

```bash
# In the ontology directory
cd ontology

# Validate and build
uv run invoke validate
uv run invoke test
uv run invoke build-site

# Deploy to Cloudflare
uv run invoke deploy
```

### Automated Deployment Test

1. Make a change to the ontology
2. Commit and push to a feature branch
3. Create a pull request to `main`
4. The workflow will:
   - ✅ Validate the ontology
   - ✅ Run all tests (including example validation)
   - ✅ Build the site
   - ❌ **NOT** deploy (PR only validates)

5. Merge the PR to `main`
6. The workflow will:
   - ✅ Validate
   - ✅ Test
   - ✅ Build
   - ✅ **Deploy to Cloudflare**

## Workflow Jobs

The deployment pipeline consists of:

### 1. `validate` Job
- Validates ontology syntax
- Runs SHACL validation tests
- Tests example instances
- Runs on: All pushes and PRs

### 2. `build-site` Job
- Generates JSON schemas
- Builds the complete site
- Validates site structure
- Creates deployment artifact
- Runs on: All pushes and PRs

### 3. `deploy-cloudflare` Job
- Deploys to Cloudflare Pages
- Updates production site
- Runs on: **Only `main` branch pushes**

### 4. `notify` Job
- Reports deployment status
- Shows URLs for verification
- Runs on: After deployment completes

## Verifying Deployment

After a successful deployment, verify:

1. **Ontology Files**
   ```bash
   curl https://clearhead.us/vocab/actions/v3/actions-vocabulary.owl
   curl https://clearhead.us/vocab/actions/v3/actions-vocabulary.ttl
   curl https://clearhead.us/vocab/actions/v3/shapes.ttl
   ```

2. **Examples**
   ```bash
   curl https://clearhead.us/vocab/actions/examples/
   curl https://clearhead.us/vocab/actions/examples/ttl/01-simple-task.ttl
   ```

3. **Web Interface**
   - Open: https://clearhead.us/vocab/actions/v3/
   - Open: https://clearhead.us/vocab/actions/examples/

## Troubleshooting

### Deployment Fails: "Invalid API token"

**Solution:** Regenerate the API token with correct permissions:
- `Account` → `Cloudflare Pages` → `Edit`

### Deployment Fails: "Project not found"

**Solution:** Create the project manually first:
```bash
cd ontology
uv run invoke build-site
wrangler pages deploy site --project-name=actions-vocabulary --branch=main
```

### Build Succeeds but Deploy Skipped

**Check:**
- Are you on the `main` branch?
- Is this a push (not a PR)?

The deploy job only runs on pushes to `main`.

### Content Not Updating

**Try:**
1. Check deployment logs in GitHub Actions
2. Verify files in the artifact:
   - Go to Actions → Latest run → Artifacts → `vocabulary-site`
3. Check Cloudflare Pages dashboard for deployment status
4. Clear Cloudflare cache if needed

## Security Best Practices

1. **Limit Token Scope:** Only grant `Cloudflare Pages` edit permission
2. **Use Environments:** The workflow uses the `production` environment
3. **Rotate Tokens:** Periodically regenerate API tokens
4. **Monitor Access:** Check Cloudflare audit logs for deployments

## Manual Deployment

If you need to deploy manually without GitHub Actions:

```bash
# From the platform root
cd ontology

# Full pipeline
uv run invoke validate
uv run invoke test
uv run pytest tests/v3/test_example_validation.py -v
uv run invoke generate-schemas
uv run invoke build-site

# Deploy
uv run invoke deploy

# Or using wrangler directly
wrangler pages deploy site --project-name=actions-vocabulary --branch=main
```

## Additional Resources

- [Cloudflare Pages Documentation](https://developers.cloudflare.com/pages/)
- [Wrangler CLI Documentation](https://developers.cloudflare.com/workers/wrangler/)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Cloudflare API Tokens](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)

## Support

If you encounter issues:

1. Check GitHub Actions logs
2. Check Cloudflare Pages deployment logs
3. Verify secrets are correctly set
4. Test manual deployment locally
5. Open an issue with deployment logs
