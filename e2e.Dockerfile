FROM node:23-slim
# install curl
RUN apt-get update && apt-get install -y curl
WORKDIR /app
COPY e2e/package.json package.json
COPY e2e/playwright.config.ts playwright.config.ts

RUN npm install && \
    npx playwright install && \
    npx playwright install-deps

RUN chown -R node:node /app
COPY --chown=node:node e2e/BaseTest.ts BaseTest.ts
COPY --chown=node:node e2e/tests tests
