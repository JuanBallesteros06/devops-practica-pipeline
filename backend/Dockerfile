# Imagen base ligera de Node
FROM node:18-alpine

# Carpeta de trabajo dentro del contenedor
WORKDIR /app

# Copiamos solo los archivos de dependencias primero (para aprovechar cache)
COPY package*.json ./

# Instalamos dependencias
RUN npm install

# Ahora copiamos el resto del código
COPY . .

# Solo informativo: el puerto donde escucha la app
EXPOSE 3000

# Comando por defecto cuando se levanta el contenedor
CMD ["npm", "start"]
