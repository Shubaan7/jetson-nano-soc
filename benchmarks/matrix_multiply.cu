#include <stdio.h>
#include <cuda_runtime.h>

#define N 1024

__global__ void matmul_naive(float *A, float *B, float *C, int n) {
	int row = blockIdx.y * blockDim.y + threadIdx.y;
	int col = blockIdx.x * blockDim.x + threadIdx.x;
	if (row < N && col < n) {
		float sum = 0.0f;
		for (int k = 0; k < N; k++) {
			sum += A[row * n + k ] * B[k * n + col];
		}
		C[row * n + col] = sum;
	}
}


int main() {
	int size = N * N * sizeof(float);
	float *h_A = (float*)malloc(size);
	float *h_B = (float*)malloc(size);
	float *h_C = (float*)malloc(size);

	for (int i = 0; i < N * N; i++) {
		h_A[i] = 1.0f;
		h_B[i] = 1.0f;
		}

	float *d_A, *d_B, *d_C;
	cudaMalloc(&d_A, size);
	cudaMalloc(&d_B, size);
	cudaMalloc(&d_C, size);

	cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
	cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);

	dim3 block(16, 16);
	dim3 grid(N/16, N/16);

	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaEventRecord(start);
	for (int i = 0; i < 10; i++) {
		matmul_naive<<<grid, block>>>(d_A, d_B, d_C, N);
	}
	cudaEventRecord(stop);
	cudaEventSynchronize(stop);

	float ms = 0;
	cudaEventElapsedTime(&ms, start, stop);
	float avg_ms = ms / 10.0f;
	float gflops = (2.0f * N * N * N) / (avg_ms * 1e6f);
	
	printf("Matrix size: %dx%d\n", N, N);
	printf("Avg time: %.2f ms\n", avg_ms);
	printf("Performance: %.2f GFLOPS\n", gflops);

	cudaFree(d_A); cudaFree(d_B); cudaFree(d_C);
	free(h_A); free(h_B); free(h_C);
	return 0;
}














