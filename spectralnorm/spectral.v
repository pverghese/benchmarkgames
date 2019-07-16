module main
import math
import os
import sync
import time

const (
    nCPU = 4
)

struct chan {
mut:
    count int
    mu sync.Mutex
}

fn (c mut chan) inc() {
    c.count++
}
fn (c mut chan) get() int {
    return c.count
}

fn evala(i, j int) int {
    return ((i+j)*(i+j+1)/2 + i + 1)
}

fn times(ii int, n int, u []f64, v mut []f64, c mut chan) {
    c.mu.lock()
    for i := ii; i < n; i++ {
        mut a := f64(0)
        for j :=0; j< u.len; j++ {
            a += u[j] /f64(evala(i,j))
        }
        v[i] = a
    }
    c.count++
    //println('Done')
    c.mu.unlock()
}

fn times_trans(ii int, n int, u []f64, v mut []f64, c mut chan) {
    //println('Len of v: ${v.len}')
    //println('ii: ${ii}, n: ${n}')
    c.mu.lock()
    for i := ii; i< n; i++ {
        //println('i:${i}')
        mut a := f64(0)
        for j :=0; j< u.len; j++ {
            //println('j:${j}')
            a += u[j] / f64(evala(j,i))
        }
        v[i] = a
    }
    c.count++
    //println('DoneT')
    c.mu.unlock()
}

fn wait_h(i int, c mut chan) {
    for {
        c.mu.lock()
        if c.count >=i {
            break
        }
        c.mu.unlock()
    }
}

fn a_times_transp(u []f64, v mut []f64) {
    mut x := [f64(0); u.len]
    mut c := chan{count:0}
    for i := 0; i< nCPU; i++ {
        //println('start: ${i * v.len/nCPU}')
        //println('end: ${(i+1)*v.len/nCPU}')
        go times(i * v.len/nCPU, (i+1)*v.len/nCPU, u, &x, &c)
    }
    wait_h(nCPU, mut c)
    c.count=0
   
    //println('c.count : ${c.count} len of v ${v.len}')
    for i := 0; i< nCPU; i++ {
        //println('start: ${i * v.len/nCPU}')
        //println('end: ${(i+1)*v.len/nCPU}')
        go times_trans(i * v.len/nCPU, (i+1)*v.len/nCPU, x, v, &c)
    }
    wait_h(nCPU, mut c)
    c.count=0 
    //x.times(u)
    //v.times_trans(x)
} 

fn main() {

    args := os.args
    mut n := int(0)

    if args.len == 2 {
        n = args[1].int()
    }
    else {
        n = 100 
    }
    println('Num: ${n}')
    mut u := [f64(1.0);n]
    mut v := [f64(1.0);n]

    for i := 0; i< 10; i++ {
        a_times_transp(u,mut v)
        a_times_transp(v, mut u)
        //println('v len: ${v.len} ulen: ${u.len}')
    }
    println('Here')

    mut vbv := f64(0)
    mut vv  := f64(0)

    for i :=0; i< n; i++ {
        vbv += u[i] * v[i]
        vv += v[i] * v[i]
    }
    ans := math.sqrt(vbv/vv)

    println('${ans:0.9f}')


}
