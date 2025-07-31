FROM node:16-alpine

ARG N8N_VERSION

# Verifica se a variável N8N_VERSION foi fornecida
RUN if [ -z "$N8N_VERSION" ] ; then echo "The N8N_VERSION argument is missing!" ; exit 1; fi

# Atualiza pacotes e instala dependências básicas
RUN apk add --update graphicsmagick tzdata git tini su-exec

USER root

# Instala n8n e dependências de build temporárias
RUN apk --update add --virtual build-dependencies python3 build-base ca-certificates \
    && npm config set python "$(which python3)" \
    && npm_config_user=root npm install -g full-icu n8n@${N8N_VERSION} \
    && apk del build-dependencies \
    && rm -rf /root /tmp/* /var/cache/apk/* && mkdir /root

# Instala Chromium e dependências para Puppeteer
RUN apk add --no-cache \
      chromium \
      nss \
      freetype \
      harfbuzz \
      ttf-freefont \
      yarn

# Configura variáveis de ambiente para Puppeteer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Instala n8n-nodes-puppeteer
RUN cd /usr/local/lib/node_modules/n8n \
    && npm install n8n-nodes-puppeteer-extended

# Instala fontes adicionais (Microsoft Core Fonts)
RUN apk --no-cache add --virtual fonts msttcorefonts-installer fontconfig \
    && update-ms-fonts \
    && fc-cache -f \
    && apk del fonts \
    && find /usr/share/fonts/truetype/msttcorefonts/ -type l -exec unlink {} \; \
    && rm -rf /root /tmp/* /var/cache/apk/* && mkdir /root

# ICU para suporte completo a internacionalização
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu

WORKDIR /data

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["tini", "--", "/docker-entrypoint.sh"]

EXPOSE 5678/tcp
