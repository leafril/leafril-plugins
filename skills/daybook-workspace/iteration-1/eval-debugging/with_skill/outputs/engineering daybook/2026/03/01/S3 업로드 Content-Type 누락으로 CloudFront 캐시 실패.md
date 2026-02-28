---
created: 2026-03-01
tags:
  - aws
  - s3
  - cloudfront
---

> [!note] Summary
> **배경**
> S3 업로드가 계속 실패하여 3시간 동안 원인을 추적했다.
>
> **원인**
> 업로드 시 Content-Type을 명시하지 않아 `application/octet-stream`으로 저장되었고, CloudFront에서 해당 응답을 올바르게 캐시하지 못했다.
>
> **결론**
> S3에 파일을 업로드할 때 Content-Type을 반드시 명시해야 한다. 누락하면 기본값인 `application/octet-stream`이 적용되어 CDN 캐시 정책과 충돌할 수 있다.

S3에 파일을 업로드하는 과정에서 계속 실패가 발생했다. 업로드 자체는 성공하는 것처럼 보였지만, CloudFront를 통해 파일을 서빙할 때 캐시가 동작하지 않는 문제였다.

3시간 동안 CloudFront 캐시 정책, 오리진 설정, 헤더 전달 규칙 등을 확인했지만 원인을 찾지 못했다. 결국 S3에 저장된 객체의 메타데이터를 직접 확인해보니 Content-Type이 `application/octet-stream`으로 설정되어 있었다. 업로드 시 Content-Type을 명시하지 않으면 S3가 기본값으로 `application/octet-stream`을 적용하는데, 이 때문에 CloudFront의 캐시 동작 조건과 맞지 않았던 것이다.

업로드 코드에 Content-Type을 명시적으로 지정하도록 수정하여 해결했다.
