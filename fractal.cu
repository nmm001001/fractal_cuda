/*
Computing a movie of zooming into a fractal

Original C++ code by Martin Burtscher, Texas State University

Reference: E. Ayguade et al., 
           "Peachy Parallel Assignments (EduHPC 2018)".
           2018 IEEE/ACM Workshop on Education for High-Performance Computing (EduHPC), pp. 78-85,
           doi: 10.1109/EduHPC.2018.00012

*/

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "timer.h"
#include "fractal.h"

static const double Delta = 0.001;
static const double xMid =  0.23701;
static const double yMid =  0.521;

__global__ void compute_frames(double aspect_ratio, int width, int height, int num_frames, unsigned char *picture_array) {
  int row = blockIdx.y*blockDim.y+threadIdx.y;
  int col = blockIdx.x*blockDim.x+threadIdx.x;
  int frame_index = blockIdx.z;
  if (frame_index >= num_frames) {
    return;
  };

  double delta = Delta * pow(0.98, frame_index);

  const double x0 = xMid - delta * aspect_ratio;
  const double y0 = yMid - delta;
  const double dx = 2.0 * delta * aspect_ratio / width;
  const double dy = 2.0 * delta / height;
  

  if (col <= width && row <= height) {
    
    const double cy = fma(dy, row, y0);
    const double cx = fma(dx, col, x0);

    double x = cx;
    double y = cy;
    int depth = 256;

    double x2;
    double y2;

    do {
      x2 = x*x;
      y2 = y*y;
      y = 2*x*y+cy;
      x = x2-y2+cx;
      depth--;
    } while ((depth > 0) && ((x2+y2) < 5.0));
    picture_array[frame_index * height * width + row * width + col] = (unsigned char) depth;
  }
}

int main(int argc, char *argv[]) {
  float start, end;

  printf("Fractal v1.6 [parallel]\n");

  /* read command line arguments */
  if (argc != 4) {fprintf(stderr, "usage: %s height width num_frames\n", argv[0]); exit(-1);}
  int width = atoi(argv[1]);
  if (width < 10) {fprintf(stderr, "error: width must be at least 10\n"); exit(-1);}
  int height = atoi(argv[2]); 
  if (height < 10) {fprintf(stderr, "error: height must be at least 10\n"); exit(-1);}
  int num_frames = atoi(argv[3]);
  if (num_frames < 1) {fprintf(stderr, "error: num_frames must be at least 1\n"); exit(-1);}
  printf("Computing %d frames of %d by %d fractal\n", num_frames, width, height);

  
  /* allocate image array */
  int pic_size = (sizeof(unsigned char) * num_frames * height * width);
  unsigned char *device_picture;
  unsigned char *host_picture = (unsigned char *)malloc(pic_size);
  GET_TIME(start);
  cudaMalloc(&device_picture, pic_size);
  
  
  dim3 threads_per_block(32, 32, 1);
  dim3 num_blocks((width+threads_per_block.x-1)/threads_per_block.x, 
  (height+threads_per_block.y-1)/threads_per_block.y, num_frames);

  double aspect_ratio = (double)width / (double)height;
  
  
  compute_frames<<<num_blocks, threads_per_block>>>(aspect_ratio, width, height, num_frames, device_picture);
  

  cudaError_t cuda_err = cudaGetLastError();
  if (cuda_err != cudaSuccess) {
    fprintf(stderr, "CUDA error: %s\n", cudaGetErrorString(cuda_err));
  }
  cudaDeviceSynchronize();
  cudaMemcpy(host_picture, device_picture, pic_size, cudaMemcpyDeviceToHost);
  cudaFree(device_picture);
  GET_TIME(end);

  /* end time */
 
  float elapsed = end - start;
  printf("Parallel compute time: %.4f s\n", elapsed);

  /* write frames to BMP files */
  if ((width <= 320) && (num_frames <= 100)) { /* do not write if images large or many */
    for (int frame = 0; frame < num_frames; frame++) {
      char name[32];
      sprintf(name, "fractal%d.bmp", frame + 1000);
      writeBMP(width, height, &host_picture[frame * height * width], name);
    }
  }


  free(host_picture);


  return 0;
} /* main */

