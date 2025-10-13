# Post-Merge Checklist

When a pull request is merged and approved, double-check the following steps to wrap up the workstream smoothly:

1. **Update Tracking Issues**
   - Close or move any related project management tasks to reflect the merged state.
   - Note the commit hash and release milestone if applicable.

2. **Cleanup Branches**
   - Delete the feature branch from the remote once the merge is complete.
   - Remove any local branches that are no longer needed to keep the workspace tidy.

3. **Communicate Status**
   - Notify stakeholders that the changes are now available on the target branch.
   - Highlight any follow-up work or testing that still needs to happen post-merge.

4. **Monitor Deployments**
   - If the merge triggers a deployment pipeline, watch for any failures or regressions.
   - Confirm that automated smoke tests pass and manually verify critical functionality when necessary.

5. **Document Lessons Learned**
   - Capture any insights from the work that could improve future iterations.
   - Update internal documentation or runbooks if processes changed during the effort.

By following this checklist, the team can ensure that merged changes are successfully integrated and communicated.
