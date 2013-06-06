#!/usr/bin/env bash

while inotifywait -re close_write . ../fonts; do sass app.scss app.css ; done
