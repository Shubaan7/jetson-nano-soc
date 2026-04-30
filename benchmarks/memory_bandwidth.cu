#include <stdio.h>
#include <cuda_runtime.h>

#define SIZE (64*1024*1024)

__global__ void copy_kernel(float *in, float *out, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) out[i] = in[i];
}

int main() {
    int bytes = SIZE * sizeof(float);
    float *h_in = (float*)malloc(bytes);
    float *h_out = (float*)malloc(bytes);
    for (int i = 0; i < SIZE; i++) h_in[i] = 1.0f;

    float *d_in, *d_out;
    cudaMalloc(&d_in, bytes);
    cudaMalloc(&d_out, bytes);
    cudaMemcpy(d_in, h_in, bytes, cudaMemcpyHostToDevice);

    int threads = 256;
    int blocks = (SIZE + threads - 1) / threads;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < 20; i++) {
        copy_kernel<<<blocks, threads>>>(d_in, d_out, SIZE);
    }
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms = 0;
    cudaEventElapsedTime(&ms, start, stop);
    float avg_ms = ms / 20.0f;
    float gb = (2.0f * SIZE * sizeof(float)) / 1e9f;
    float bandwidth = gb / (avg_ms / 1000.0f);

    printf("Avg time: %.2f ms\n", avg_ms);
    printf("Bandwidth: %.2f GB/s\n", bandwidth);
    printf("Theoretical max: 25.6 GB/s\n");

    cudaFree(d_in); cudaFree(d_out);
    free(h_in); free(h_out);
    return 0;
}
