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

#include "qemu/req-count.h"
#include "block/aio.h"

void request_count_drain(AioContext *ctx, RequestCount *r)
{
    if (aio_context_in_iothread(ctx)) {
        while (atomic_read(&r->count)) {
            aio_poll(ctx, true);
        }
    } else {
        assert(qemu_get_current_aio_context() == qemu_get_aio_context());
        assert(!r->wakeup);

        /* Store r->wakeup before reading r->count.  */
        atomic_mb_set(&r->wakeup, true);
        while (atomic_read(&r->count)) {
            aio_poll(qemu_get_aio_context(), true);
        }
        atomic_set(&r->wakeup, false);
    }
}

void request_count_wakeup(RequestCount *r)
{
    /* Store r->count before reading r->wakeup.  */
    if (atomic_read(&r->wakeup)) {
        aio_wakeup(qemu_get_aio_context());
    }
}
