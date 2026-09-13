// Optional. Only for repos that already have a Node toolchain (fronts, rfacil-ui).
// Everything else validates in CI with the reusable workflow
// .github/workflows/conventional-commits.yml, which needs no dependencies.
//
// Types are the closed list of ENG-STD-001 section 7.2, plus "merge".
// Declare the repo's own closed scope list in scope-enum (section 7.3).
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [2, 'always', [
      'build', 'chore', 'ci', 'deprecate', 'docs', 'feat', 'fix',
      'merge', 'perf', 'refactor', 'revert', 'security', 'style', 'test',
    ]],
    'header-max-length': [2, 'always', 72],
    'subject-empty': [2, 'never'],
    // 'scope-enum': [2, 'always', ['back', 'front', 'api-contract']],
  },
};
