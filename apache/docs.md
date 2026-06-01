# Triển khai apache HA 

## I. Mô hình 

## II. Cài đặt 

### 2.0 Triển khai service apache trên swarm 

**Bước 1:** Tạo overlay network 

```bash
docker network create \
  --driver overlay \
  web-network
```