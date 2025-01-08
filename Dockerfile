# # Copyright 2024-2025 NetCracker Technology Corporation
# #
# # Licensed under the Apache License, Version 2.0 (the "License");
# # you may not use this file except in compliance with the License.
# # You may obtain a copy of the License at
# #
# #      http://www.apache.org/licenses/LICENSE-2.0
# #
# # Unless required by applicable law or agreed to in writing, software
# # distributed under the License is distributed on an "AS IS" BASIS,
# # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# # See the License for the specific language governing permissions and
# # limitations under the License.
#

FROM golang:1.22.6-alpine3.20 AS builder

ENV USER_UID=2001 \
    USER_NAME=appuser \
    GROUP_NAME=appuser

COPY /cmd/graphite-remote-adapter /bin/graphite-remote-adapter
EXPOSE 9092
VOLUME "/graphite-remote-adapter"

RUN chmod +x /bin/graphite-remote-adapter \
    && addgroup ${GROUP_NAME} \
    && adduser -D -G ${GROUP_NAME} -u ${USER_UID} ${USER_NAME}

RUN echo 'https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/' > /etc/apk/repositories \
    && apk add --upgrade \
        lz4-libs \
    && rm -rf /var/cache/apk/*

WORKDIR /graphite-remote-adapter

USER ${USER_UID}

ENTRYPOINT [ "/bin/graphite-remote-adapter" ]
CMD [ "-graphite-address=localhost:2003" ]
