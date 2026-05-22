@echo off
echo ============================================
echo  Inicializando contenedor de Ubunut 26.04 para datacenter.sh
echo ============================================
echo.
docker pull ubuntu:26.04 >nul 2>&1
docker run -it --rm -v "%CD%:/scripts" ubuntu:26.04 bash -c "apt update && DEBIAN_FRONTEND=noninteractive apt install -y login util-linux procps findutils coreutils && cd /scripts && chmod +x bash/datacenter.sh && bash bash/datacenter.sh"
