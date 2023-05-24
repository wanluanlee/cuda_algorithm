#include <iostream>
#include <vector>
#include <numeric>
#define FULL_MASK 0xffffffff

__global__
void scan(int* d_in, int N) {
  //unsigned mask = __ballot_sync(FULL_MASK, threadIdx.x < N);
  int tid = threadIdx.x;
  __shared__ int tmp[32];
  int tmp1, tmp2, tmp3;
  if(threadIdx.x > N) {
    return;
  }
  //if(threadIdx.x < N) {
    tmp1 = d_in[threadIdx.x];
    for(int off = 1; off < N; off *= 2) {
      tmp2 = __shfl_up_sync(FULL_MASK, tmp1, off);
      if(threadIdx.x % 32 >= off) {
        tmp1 += tmp2;
      }
    }
    if(tid % 32 == 31) {
      tmp[tid/32] = tmp1;
    }
    __syncthreads();
    if(threadIdx.x == 0) {
      for(int i = 0; i < 32; i++) {
        printf("i:%d, share val:%d \n", i, tmp[i]);
      }
    }
    __syncthreads();
    //printf("threadIdx.x:%d, tmp1:%d \n", threadIdx.x, tmp1);
  //}
  if(tid < 32) {
    tmp2 = 0.0f;
    if(tid < blockDim.x/32) {
      tmp2 = tmp[tid];
      printf("tmp2:%d, tid:%d, blockDim.x:%d \n", tmp2, tid, blockDim.x);
    }
    for(int off = 1; off < 32; off <<=1) {
      tmp3 = __shfl_up_sync(FULL_MASK, tmp2, off);
      printf("tmp3:%d, tmp2:%d, tid:%d \n", tmp3, tmp2, tid);
      if(tid % 32 >= off) {
        tmp2 += tmp3;
      }
    }
    if(tid < blockDim.x /32) {
      tmp[tid] = tmp2;
    }
  }
  __syncthreads();
  if(tid >= 32) {
    tmp1 += tmp[tid/32-1];
  }  
  d_in[threadIdx.x] = tmp1;

}

int main() {

 const int N = 1030;
 std::vector<int> h_in(N,0);
 std::vector<int> h_cpu_out(N,0);

 for(int i = 0; i < N; i++) {
   h_in[i] = 1;
 }
 int* d_in;
 cudaMalloc((void**)&d_in, sizeof(int) * N);
 cudaMemcpy(d_in, h_in.data(), sizeof(int)*N, cudaMemcpyHostToDevice);
 
 scan <<< 2, 1024>>> (d_in, N);
 cudaDeviceSynchronize();

 cudaMemcpy(h_in.data(), d_in, sizeof(int)*N, cudaMemcpyDeviceToHost);
 //std::exclusive_scan(h_in.begin(), h_in.end(), h_cpu_out.begin(), 0);
 for(int i = 0; i < N; i++) {
   std::cout << "i:" << i << ", val: " << h_in[i] << '\n';
 }
 cudaFree(d_in);
  return 0;
}
