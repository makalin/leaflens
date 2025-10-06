# Contributing to LeafLens

Thank you for your interest in contributing to LeafLens! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Community Guidelines](#community-guidelines)

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/yourusername/leaflens.git`
3. Create a feature branch: `git checkout -b feature/amazing-feature`
4. Make your changes
5. Commit your changes: `git commit -m 'Add amazing feature'`
6. Push to the branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

## Development Setup

### Prerequisites

- **Flutter**: 3.10.0 or higher
- **Rust**: 1.75 or higher
- **Docker**: 20.10 or higher
- **Python**: 3.8 or higher (for ML training)
- **Node.js**: 16 or higher (for tooling)

### Mobile App Development

```bash
# Navigate to app directory
cd app

# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Backend Development

```bash
# Navigate to server directory
cd server

# Install dependencies
cargo build

# Run the server
cargo run

# Run tests
cargo test

# Format code
cargo fmt

# Lint code
cargo clippy
```

### ML Model Development

```bash
# Navigate to research directory
cd research

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run training
python train_classifier.py --config configs/default.yaml
```

### Full Stack Development

```bash
# Start all services with Docker Compose
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Contributing Guidelines

### Code Style

- **Flutter/Dart**: Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- **Rust**: Use `cargo fmt` and `cargo clippy`
- **Python**: Follow PEP 8, use `black` for formatting
- **YAML/TOML**: Use consistent indentation and formatting

### Commit Messages

Use conventional commits format:

```
type(scope): description

[optional body]

[optional footer(s)]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(diagnosis): add confidence scoring for predictions
fix(camera): resolve image capture orientation issue
docs(api): update OpenAPI specification
```

### Testing

- Write tests for new features
- Ensure all tests pass before submitting PR
- Add integration tests for API endpoints
- Test on multiple devices/platforms when possible

### Documentation

- Update README.md for significant changes
- Add JSDoc comments for complex functions
- Update API documentation for new endpoints
- Include examples in documentation

## Pull Request Process

1. **Fork and Branch**: Create a feature branch from `main`
2. **Develop**: Make your changes with proper tests
3. **Test**: Ensure all tests pass locally
4. **Document**: Update documentation as needed
5. **Submit**: Create a pull request with a clear description

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots (if applicable)
Add screenshots to help explain your changes

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

## Issue Reporting

### Bug Reports

Use the bug report template and include:

- **Description**: Clear description of the bug
- **Steps to Reproduce**: Detailed steps to reproduce
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Environment**: OS, Flutter version, device info
- **Screenshots**: If applicable
- **Logs**: Relevant error logs

### Feature Requests

Use the feature request template and include:

- **Description**: Clear description of the feature
- **Use Case**: Why this feature is needed
- **Proposed Solution**: How you think it should work
- **Alternatives**: Other solutions considered
- **Additional Context**: Any other relevant information

## Community Guidelines

### Getting Help

- **Documentation**: Check the README and docs first
- **Issues**: Search existing issues before creating new ones
- **Discussions**: Use GitHub Discussions for questions
- **Discord**: Join our Discord server for real-time chat

### Code Review

- Be constructive and respectful
- Focus on the code, not the person
- Suggest improvements, don't just point out problems
- Ask questions if something is unclear
- Acknowledge good work

### Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project documentation
- Community highlights

## Development Workflow

### Branch Naming

- `feature/description`: New features
- `fix/description`: Bug fixes
- `docs/description`: Documentation updates
- `refactor/description`: Code refactoring
- `test/description`: Test improvements

### Release Process

1. **Version Bump**: Update version numbers
2. **Changelog**: Update CHANGELOG.md
3. **Release Notes**: Create release notes
4. **Tag**: Create git tag
5. **Build**: Build and test all components
6. **Deploy**: Deploy to staging/production

## Areas for Contribution

### High Priority
- [ ] Additional crop support
- [ ] Improved ML model accuracy
- [ ] Better offline functionality
- [ ] Performance optimizations
- [ ] Accessibility improvements

### Medium Priority
- [ ] New plugin development
- [ ] API enhancements
- [ ] UI/UX improvements
- [ ] Documentation updates
- [ ] Test coverage

### Low Priority
- [ ] Code refactoring
- [ ] Tooling improvements
- [ ] Community features
- [ ] Localization
- [ ] Analytics

## Getting Help

- **Email**: support@leaflens.com
- **Discord**: [Join our server](https://discord.gg/leaflens)
- **GitHub Issues**: [Create an issue](https://github.com/makalin/leaflens/issues)
- **Documentation**: [Read the docs](https://docs.leaflens.com)

## License

By contributing to LeafLens, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to LeafLens! 🌱