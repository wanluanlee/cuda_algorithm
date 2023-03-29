#include <cuda.h>
#include <vector>
#include <iostream>
#include <string>
#define THREAD_PER_BLOCK 8

  struct mv {

    int vertex_id;
    int source_partition;
    int des_partition;
    int gain;

    mv() = default;

    __host__ __device__
    mv(int vertex_id,
              int source_partition,
              int des_partition,
              int gain) :
              vertex_id(vertex_id),
              source_partition(source_partition),
              des_partition(source_partition),
              gain(gain) {};
  };

__device__
  void swap(mv* d_data, int idx_1, int idx_2) {
    mv tmp = d_data[idx_1];
    d_data[idx_1] = d_data[idx_2];
    d_data[idx_2] = tmp;
  }

//__global__
  //void even_sort(int* d_data, int N) {
    //int gid = blockIdx.x * blockDim.x + threadIdx.x;
    //int idx = gid * 2;
    //if(idx <= (N - 2)) {
      //swap(d_data, idx, idx+1);
    //}
  //}

//__global__
  //void odd_sort(int* d_data, int N) {
    //int gid = blockIdx.x * blockDim.x + threadIdx.x;
    //int idx = gid * 2 + 1;
    //if(idx <= (N - 2)) {
      //swap(d_data, idx, idx+1);
    //}
  //}

__global__ 
  void odd_even_kernel(mv* d_data, int start_idx, int N, int num_thread_need) {
    int gid = blockIdx.x * blockDim.x + threadIdx.x;

    if(gid < num_thread_need) {
      int idx = 2 * gid + start_idx;
      if(idx < (N - 1) && d_data[idx].gain > d_data[idx + 1].gain) {
        swap(d_data, idx, idx + 1);
      }
    }
  }

  void odd_even_sort(mv* h_data, int N) {
    cudaError_t cudaStatus;
    mv* d_data;
    cudaMalloc((void**)&d_data, sizeof(mv) * N);
    cudaMemcpy(d_data, h_data, sizeof(mv) * N, cudaMemcpyHostToDevice);
    //int num_thread_need = (N - 1) / 2 + (N - 1) % 2;
    int num_thread_need = N / 2;
    std::cout << "num_thread_need: " << num_thread_need << '\n';
    int num_block = (num_thread_need  + THREAD_PER_BLOCK - 1) / THREAD_PER_BLOCK;
    for(int i = 0; i < N; i ++) {
      //odd_even_kernel<<< num_block, std::min(num_thread_need, THREAD_PER_BLOCK) >>> (d_data, i % 2, N, num_thread_need); 
      odd_even_kernel<<< num_block, THREAD_PER_BLOCK >>> (d_data, i % 2, N, num_thread_need); 
    }
    cudaMemcpy(h_data, d_data, sizeof(mv) * N, cudaMemcpyDeviceToHost);
    cudaFree(d_data);
  }

  //void odd_even_sort(int* h_data, int N) {
    //cudaError_t cudaStatus;
    //int* d_data;
    //cudaMalloc((void**)&d_data, sizeof(int) * N);
    //cudaMemcpy(d_data, h_data, sizeof(int) * N, cudaMemcpyHostToDevice);
    ////int num_thread_need = (N - 1) / 2 + (N - 1) % 2;
    //int num_block = (N  + THREAD_PER_BLOCK - 1) / THREAD_PER_BLOCK;
    //for(int i = 0; i <= N/2; i ++) {
      //even_sort<<< num_block, THREAD_PER_BLOCK >>> (d_data, N); 
      //odd_sort<<< num_block, THREAD_PER_BLOCK >>> (d_data, N); 
    //}
    //cudaMemcpy(h_data, d_data, sizeof(int) * N, cudaMemcpyDeviceToHost);
    //cudaFree(d_data);
  //}

  int main(int argc, char** argv) {

    //std::vector<int> h_in = {1,5,3,2,4,7,8,11,6,3,12,4,1,6,8};
    const int N = std::stoi(argv[1]);
    std::vector<mv> h_in = {};

    for(int i = 0 ; i < N; i++) {
      mv mv_request;
      mv_request.vertex_id = i;
      mv_request.source_partition = rand()%4;
      mv_request.des_partition = rand()%4;
      mv_request.gain = rand()%15;
      h_in.push_back(mv_request);
    }
 
    for(int i = 0; i < h_in.size(); i++) {
      std::cout << "before sort, i: " << i << '\n';
      std::cout << "mv.vertex_id: " << i << ", mv.source_partition: " << h_in[i].source_partition << ", des_partition: " << h_in[i].des_partition << ", mv.gain: " << h_in[i].gain << '\n';
      std::cout << "-----------------------------\n";
    }
    odd_even_sort(h_in.data(), h_in.size());
    for(int i = 0; i < h_in.size(); i++) {
      std::cout << "after sort, i: " << i << '\n';
      std::cout << "mv.vertex_id: " << i << ", mv.source_partition: " << h_in[i].source_partition << ", des_partition: " << h_in[i].des_partition << ", mv.gain: " << h_in[i].gain << '\n';
      std::cout << "-----------------------------\n";
    }
    return 0;
  }
