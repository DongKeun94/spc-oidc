# 베이스 이미지 선택
FROM ubuntu:22.04

# tzdata 설치 시 대화형 입력 방지
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul

# 필수 패키지 설치
RUN apt-get update && \
    apt-get install -y \
      curl \
      jq \
      awscli \
      ca-certificates \
      && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
      && dpkg-reconfigure --frontend noninteractive tzdata \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

# GitHub Actions OIDC 스크립트 복사
WORKDIR /action
COPY entrypoint.sh /action/entrypoint.sh
RUN chmod +x /action/entrypoint.sh

# 환경변수 기본값 설정 (AWS 체크섬 관련)
ENV AWS_RESPONSE_CHECKSUM_VALIDATION=when_required
ENV AWS_REQUEST_CHECKSUM_CALCULATION=when_required

# 액션 실행
ENTRYPOINT ["/action/entrypoint.sh"]
