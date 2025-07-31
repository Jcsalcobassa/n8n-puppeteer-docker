FROM node:16-alpine

# Define uma versão padrão caso a variável não seja passada
ARG N8N_VERSION=1.83.2

# Atualiza pacotes e instala dependências necessárias
RUN apk add --update graphicsmagick tzdata git tini su-exec

# Define o usuário root temporariamente
USER root

# Instala o n8n e dependências de build
RUN apk --update add --virtual build-dependencies python3 build-base ca-certificates \
  && npm config set python "$(which python3)" \
  && npm_config_user=root npm install -g full-icu n8n@${N8N_VERSION} \
  && apk del build-dependencies \
  && rm -rf /root /tmp/* /var/cache/apk/* \
  && mkdir /root

# Instala o Chromium e fontes para o Puppeteer funcionar
RUN apk add --no-cache \
  chromium \
  nss \
  freetype \
  harfbuzz \
  ttf-freefont \
  yarn

# Informa ao Puppeteer para usar o Chromium já instalado
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Instala o node n8n-nodes-puppeteer-extended
RUN cd /usr/local/lib/node_modules/n8n \
  && npm install n8n-nodes-puppeteer-extended

# Instala fontes adicionais da Microsoft
RUN apk --no-cache add --virtual fonts msttcorefonts-installer fontconfig \
  && update-ms-fonts \
  && fc-cache -f \
  && apk del fonts \
  && find /usr/share/fonts/truetype/msttcorefonts/ -type l -exec unlink {} \; \
  && rm -rf /root /tmp/* /var/cache/apk/* \
  && mkdir /root

# Define dados de localização e local de trabalho
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu
WORKDIR /data

# Copia o entrypoint personalizado
COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]

EXPOSE 5678/tcp
