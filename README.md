# Fractal.cu

Parallel implementation of fractal.c by Martin Burtscher (Texas State University) using CUDA API

## Before running
Make sure you have CUDA compatible device by running the following command...

```bash
nvidia-smi
```
and checking to see what version of cuda you have.

Then make sure you have the proper CUDA compiler by running the following command...
```bash
nvcc --version
```

## To compile
```python
nvcc fractal.cu -o fractal_cu
```

## To run
```bash
./fractal_cu <width> <height> <frames>

./fractal_cu 4096 2160 120
```

## To convert output to GIF
```bash
convert -delay 1x30 fractal*.bmp fractal.gif
```

## Reference
Original C++ code by Martin Burtscher, Texas State University

E. Ayguade et al., 
           "Peachy Parallel Assignments (EduHPC 2018)".
           2018 IEEE/ACM Workshop on Education for High-Performance Computing (EduHPC), pp. 78-85,
           doi: 10.1109/EduHPC.2018.00012
