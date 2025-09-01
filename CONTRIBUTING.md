# Contributing to Buildables Neu Todo

We love your input! We want to make contributing to this project as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

## Pull Requests

Pull requests are the best way to propose changes to the codebase. We actively welcome your pull requests:

1. Fork the repo and create your branch from `master`.
2. If you've added code that should be tested, add tests.
3. If you've changed APIs, update the documentation.
4. Ensure the test suite passes.
5. Make sure your code lints.
6. Issue that pull request!

## Development Setup

1. **Prerequisites**
   - Flutter SDK (3.8.1+)
   - Android Studio or VS Code
   - Git

2. **Setup**
   ```bash
   git clone https://github.com/LDrago-zae/buildables_neu_todo.git
   cd buildables_neu_todo
   flutter pub get
   ```

3. **Environment**
   - Copy `.env.example` to `.env` (if exists)
   - Set up your Supabase credentials

## Coding Standards

- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Write comments for complex logic
- Maintain the existing architecture patterns
- Ensure offline functionality works

## Testing

- Add unit tests for business logic
- Add widget tests for UI components
- Ensure existing tests pass before submitting PR
- Test offline functionality

## Bug Reports

**Great Bug Reports** tend to have:

- A quick summary and/or background
- Steps to reproduce
  - Be specific!
  - Give sample code if you can
- What you expected would happen
- What actually happens
- Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)

## Feature Requests

We're always open to new feature ideas! Please:

- Check if the feature already exists
- Explain the use case
- Consider the scope and complexity
- Be open to discussion about implementation

## Questions?

Feel free to open an issue with the "question" label, or reach out to the maintainers.

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.