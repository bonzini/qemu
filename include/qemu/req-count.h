/*
 * Abstraction for counting pending requests
 *
 * Copyright (C) 2017 Red Hat, Inc.
 *
 * Author: Paolo Bonzini <pbonzini@redhat.com>
 *
 * This work is licensed under the terms of the GNU GPL, version 2.  See
 * the COPYING file in the top-level directory.
 */

#ifndef QEMU_REQ_COUNT_H
#define QEMU_REQ_COUNT_H

#include <qemu/atomic.h>

typedef struct RequestCount {
    unsigned count;
    bool wakeup;
}

#define REQUEST_COUNT_NEED_WAKEUP   0x80000000u

/**
 * request_count_begin: track the beginning of a request
 * @r: the @RequestCount to work on.
 *
 * A request_count_drain() that starts after this request_count_begin()
 * will wait for the corresponding request_count_end() before exiting.
 */
static inline void request_count_begin(RequestCount *r)
{
    atomic_inc(&r->count);
}

/**
 * request_count_end: track the end of a request
 * @r: the @RequestCount to work on.
 *
 * A request has been processed; if it is the last, wake up any concurrent
 * request_count_drain() call.
 */
static inline void request_count_end(RequestCount *r)
{
    int cnt = r->count - 1;

    if (atomic_fetch_dec(&r->count, cnt) == 0) {
        request_count_wakeup(r);
    }
}

/**
 * request_count_drain: wait for the request counter to reach zero
 * @ctx: the @AioContext to wait on.
 * @r: the @RequestCount to work on.
 *
 * Wait until @ctx completes the last request on @s.  If @ctx is not
 * the current AioContext, request_count_end() will take care of waking
 * up request_count_drain().
 */
void request_count_drain(AioContext *ctx, RequestCount *s);

/**
 * request_count_wakeup: internal function for request_count_end()
 * @r: the @RequestCount to work on.
 *
 * This function is called by request_count_end() when the count goes
 * down to zero.  You do not need it.
 */
void request_count_wakeup(RequestCount *s);

#endif
