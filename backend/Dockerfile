# ---------- Etapa 1: Build ----------
FROM node:18-alpine AS build
WORKDIR /app

# Copiamos package.json e instalamos dependencias
COPY package*.json ./
RUN npm ci --only=production

# Copiamos el resto del código
COPY . .

# ---------- Etapa 2: Runtime ----------
FROM node:18-alpine
WORKDIR /app

# Copiar dependencias y código de la etapa anterior
COPY --from=build /app /app

# Exponer el puerto del backend
EXPOSE 3000

# Comando de inicio
CMD ["npm", "run", "start"]
