---
created: 2026-03-01
tags:
  - aws
  - s3
  - cloudfront
---

> [!note] Summary
> **고민**
> S3 업로드가 계속 실패하는데 원인을 못 찾겠음. 3시간 동안 삽질.
>
> **결과**
> - 업로드 시 Content-Type을 명시하지 않아 `application/octet-stream`으로 저장되고 있었음
> - CloudFront가 Content-Type 기반으로 캐시 동작을 결정하는데, octet-stream이라 캐시가 안 됐던 것
>
> **다음**
> 업로드 로직에서 파일 확장자에 맞는 Content-Type을 명시적으로 지정하도록 수정

[[S3]]에 파일을 업로드하는데 계속 실패했다. 정확히 말하면 업로드 자체는 됐는데, CloudFront를 통해 파일을 서빙할 때 캐시가 전혀 동작하지 않았다.

처음에는 CloudFront 캐시 정책 설정 문제인 줄 알고 TTL, 캐시 키 설정 등을 이리저리 바꿔봤는데 소용없었다. 버킷 정책도 확인하고, 오리진 설정도 다시 봤다.

3시간쯤 지나서 S3에 올라간 파일의 메타데이터를 직접 확인했더니 Content-Type이 전부 `application/octet-stream`으로 되어 있었다. 업로드할 때 Content-Type을 따로 지정하지 않으면 S3가 기본값으로 octet-stream을 넣는다. CloudFront는 Content-Type에 따라 캐시 동작이 달라지는데, octet-stream은 바이너리 스트림 취급이라 캐시가 기대한 대로 동작하지 않았던 것이다.

업로드 시 파일 확장자에 맞는 Content-Type(예: `image/jpeg`, `text/css`)을 명시적으로 지정하니 바로 해결됐다.

**교훈:** S3 업로드 시 Content-Type은 반드시 명시한다. S3 기본값인 octet-stream은 CDN 캐싱, 브라우저 렌더링 등 다운스트림 동작에 전부 영향을 준다.
