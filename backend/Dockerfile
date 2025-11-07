# ---- Stage 1: Build the application ----
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build || echo "No build step defined"

# ---- Stage 2: Production image ----
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app /app
RUN npm ci --production
EXPOSE 3000
CMD ["npm", "start"]
