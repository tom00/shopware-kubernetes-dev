FROM node:23-slim
# install curl
RUN apt-get update && apt-get install -y curl
WORKDIR /app
COPY e2e/package.json package.json
COPY e2e/playwright.config.ts playwright.config.ts

RUN npm install && \
    npx playwright install && \
    npx playwright install-deps

RUN chown -R 1001:node /app
COPY --chown=1001:node e2e/BaseTest.ts BaseTest.ts
COPY --chown=1001:node e2e/tests tests
# GitHub Actions UID
USER 1001
