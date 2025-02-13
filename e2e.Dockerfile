FROM node:23-slim
# install dependencies and change user & group id to 1001 for GitHub Actions compatibility
RUN apt-get update && apt-get install -y curl && \
    usermod -u 1001 node && \
    groupmod -g 1001 node && \
    chown -R 1001:1001 /home/node

WORKDIR /app
COPY --chown=node:node e2e/package.json package.json
COPY --chown=node:node e2e/playwright.config.ts playwright.config.ts

RUN npm install && \
    npx playwright install && \
    npx playwright install-deps && \
    cp -R /root/.cache /home/node/.cache

RUN chown -R node:node /app
COPY --chown=node:node e2e/BaseTest.ts BaseTest.ts
COPY --chown=node:node e2e/tests tests
USER node
