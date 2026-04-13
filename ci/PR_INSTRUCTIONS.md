Push & PR instructions

If you want me to push and create a PR automatically, provide a remote URL in this form:

  git remote add origin git@github.com:<org_or_user>/<repo>.git
  git push -u origin impl/dungeon-seed

To open a PR manually (recommended if you want to review before pushing):
1. Add remote (if not already):
   git remote add origin git@github.com:<org_or_user>/<repo>.git
2. Push branch:
   git push -u origin impl/dungeon-seed
3. Create PR via GitHub UI or CLI:
   gh pr create --base main --head impl/dungeon-seed --title "Impl: Dungeon Seed core systems" --body-file PR_BODY.md

If you prefer me to push and open the PR for you, provide the remote URL now (I will push and call gh pr create). If not, follow the steps above manually.

Security: Do NOT expose HMAC keys or secrets in PR description or commits. Use repo secrets for CI.
