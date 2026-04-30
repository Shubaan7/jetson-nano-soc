#include <stdio.h>
#include <cuda_runtime.h>

#define SIZE (1024*1024)

__global__ void fma_kernel(float *out, float a, float b, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        float x = a;
        for (int j = 0; j < 1000; j++) {
            x = x * a + b;
        }
        out[i] = x;
    }
}

int main() {
    int bytes = SIZE * sizeof(float);
    float *d_out;
    cudaMalloc(&d_out, bytes);

    int threads = 256;
    int blocks = (SIZE + threads - 1) / threads;

    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    for (int i = 0; i < 10; i++) {
        fma_kernel<<<blocks, threads>>>(d_out, 1.0001f, 0.0001f, SIZE);
    }
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms = 0;
    cudaEventElapsedTime(&ms, start, stop);
    float avg_ms = ms / 10.0f;
    float ops = (float)SIZE * 1000.0f * 2.0f * 10.0f;
    float gflops = ops / (avg_ms * 1e6f);

    printf("Avg time: %.2f ms\n", avg_ms);
    printf("Compute throughput: %.2f GFLOPS\n", gflops);
    printf("Theoretical peak: 236 GFLOPS\n");

    cudaFree(d_out);
    return 0;
}
