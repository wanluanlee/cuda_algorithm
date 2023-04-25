#include <iostream>
#include <vector>

//__global__
//void scan(int* d_in, int* d_out, int N) {

  //extern __shared__ int temp[];
  //unsigned tid = threadIdx.x;
  //if(tid > N) {
    //return;
  //}
  //int pout = 0; 
  //int pin = 1;
  //temp[tid*N+tid] = (tid > 0) ? d_in[tid-1] : 0;

  //__syncthreads();
  //if(threadIdx.x == 0) {
    //for(int i = 0; i <= N; i++) {
      //printf("i:%d, temp:%d \n", i, temp[i]);
 
    //}

  //}

  //__syncthreads();
  //for(int offset = 1; offset < N; offset *= 2) {
    //pout = 1 - pout;
    //pin = 1 - pout;

    //if(tid >= offset) {
      //temp[pout*N+tid] += temp[pin*N+tid - offset];
      //printf("tid:%d, pout:%d, pin:%d, idx_left:%d, idx_right:%d, offset:%d \n", tid, pout, pin, pout*N+tid, pin*N+tid-offset, offset);
    //}
    //else {
      //temp[pout*N+tid] = temp[pin*N+tid];
      //printf(" less offset, tid:%d, pout:%d, pin:%d, idx_left:%d, idx_right:%d, offset:%d \n", tid, pout, pin, pout*N+tid, pin*N+tid-offset, offset);
    //}
    //__syncthreads();
  //}

  //d_out[tid] = temp[pout*N+tid];
//}

__global__
void scan(int* d_in, int* d_out, int N) {
  int tmp;
  for(int off = 1; off < N; off *= 2) {
    if(threadIdx.x >= off) {
      tmp = d_in[threadIdx.x - off];
      //printf("in idx:%d, d_in:%d \n", threadIdx.x - off, d_in[threadIdx.x-off]);
    }
    __syncthreads();
    if(threadIdx.x >= off) {
      d_in[threadIdx.x] += tmp;
      //printf("write to out idx:%d \n", threadIdx.x);
    }
    __syncthreads();
  }

}

int main() {

 std::vector<int> h_in = {0,2,4,6,7,12,14};
 const int N = h_in.size();
 int* d_in;
 int* d_out;
 int* h_out = (int*) malloc(sizeof(int)*N);
 cudaMalloc((void**)&d_in, sizeof(int) * N);
 cudaMalloc((void**)&d_out, sizeof(int) * N);
 cudaMemcpy(d_in, h_in.data(), sizeof(int)*N, cudaMemcpyHostToDevice);

 scan <<< 1, N>>> (d_in, d_out, N);
 //cudaDeviceSynchronize();

 cudaMemcpy(h_out, d_in, sizeof(int)*N, cudaMemcpyDeviceToHost);
 for(int i = 0; i < N; i++) {
   std::cout << "i:" << i << ", val: " << h_out[i] << '\n';
 }
 cudaFree(d_in);
 cudaFree(d_out);
 free(h_out);
  return 0;
}
