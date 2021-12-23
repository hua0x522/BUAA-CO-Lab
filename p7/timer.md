## 一.状态转移图

### 模式0

![模式1](C:\Users\wangxuezhu\Desktop\p7\模式1.png)

### 模式1

![模式2](C:\Users\wangxuezhu\Desktop\p7\模式2.png)

## 二.计时器使用说明

### 1.模式0

当ctrl[0]置为1时，计时器进入LOAD状态并清零IRQ，在LOAD状态下从preset寄存器加载count值，即计时时长。之后进入CNT状态，在CNT状态等待count个周期后，产生中断信号IRQ，进入INT状态，把ctrl[0]置为0。

模式 0 通常用于产生定时中断。在实际操作中，只需要提前设定好preset寄存器的值作为定时，然后将ctrl[0]置为1，即可开始倒计时。倒计时结束后，中断信号将会持续有效，直到下一次倒计时开始，即ctrl[0]置为1。

需要注意倒计时的过程中不能把ctrl[0]置为0，否则计时将会结束，不会产生中断。

### 2.模式1

当ctrl[0]置为1时，计时器进入LOAD状态并清零IRQ，在LOAD状态下从preset寄存器加载count值，即计时时长。之后进入CNT状态，在CNT状态等待count个周期后，产生中断信号IRQ，进入INT状态，把IRQ置为0。

模式1用来产生周期性中断信号。每经过preset个周期，计时器就会把IRQ信号置为1，维持一个周期。每次计时结束后立即开始下一次计时，无需手动设置ctrl[0]。

需要注意不能把ctrl[0]置为0，否则计时将会结束，不再产生中断。