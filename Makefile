# Makefile for K3d Stack Development

.PHONY: help helm-test helm-lint helm-template

# Default target
help:
	@echo "Available targets:"
	@echo "  helm-test     - Run Helm lint and template validation"
	@echo "  helm-lint     - Run Helm lint on charts"
	@echo "  helm-template - Generate and validate Helm templates"

# Helm test target - combines lint and template validation
helm-test:
	@echo "Running Helm tests..."
	@if [ -d "charts/votchain" ]; then \
		echo "Testing votchain chart..."; \
		helm dependency update charts/votchain; \
		helm lint charts/votchain; \
		helm template charts/votchain --values charts/votchain/values.yaml > /dev/null; \
	else \
		echo "No votchain chart found, testing common-library..."; \
		helm lint charts/common-library; \
	fi
	@echo "Helm tests completed successfully!"

# Individual lint target
helm-lint:
	@echo "Running Helm lint..."
	@if [ -d "charts/votchain" ]; then \
		helm lint charts/votchain; \
	else \
		helm lint charts/common-library; \
	fi

# Template validation target
helm-template:
	@echo "Validating Helm templates..."
	@if [ -d "charts/votchain" ]; then \
		helm template charts/votchain --values values-global.yaml > /dev/null; \
	else \
		echo "No votchain chart found for template validation"; \
	fi
