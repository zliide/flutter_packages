// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.example.test_plugin

import io.flutter.plugin.common.BinaryMessenger
import io.mockk.every
import io.mockk.mockk
import io.mockk.slot
import io.mockk.verify
import java.nio.ByteBuffer
import java.util.ArrayList
import junit.framework.TestCase
import org.junit.Test

internal class EnumTest : TestCase() {
  @Test
  fun testEchoHost() {
    val binaryMessenger = mockk<BinaryMessenger>()
    val api = mockk<EnumApi2Host>()

    val channelName = "dev.flutter.pigeon.pigeon_integration_tests.EnumApi2Host.echo"
    val input = DataWithEnum(EnumState.SNAKE_CASE)

    val handlerSlot = slot<BinaryMessenger.BinaryMessageHandler>()

    every { binaryMessenger.setMessageHandler(channelName, capture(handlerSlot)) } returns Unit
    every { api.echo(any()) } returnsArgument 0

    EnumApi2Host.setUp(binaryMessenger, api)

    val codec = EnumApi2Host.codec
    val message = codec.encodeMessage(listOf(input))
    message?.rewind()
    handlerSlot.captured.onMessage(message) {
      it?.rewind()
      @Suppress("UNCHECKED_CAST") val wrapped = codec.decodeMessage(it) as List<Any>?
      assertNotNull(wrapped)
      wrapped?.let {
        assertNotNull(wrapped[0])
        assertEquals(input, wrapped[0])
      }
    }

    verify { binaryMessenger.setMessageHandler(channelName, handlerSlot.captured) }
    verify { api.echo(input) }
  }

  @Test
  fun testEchoFlutter() {
    val binaryMessenger = mockk<BinaryMessenger>()
    val api = EnumApi2Flutter(binaryMessenger)

    val input = DataWithEnum(EnumState.SNAKE_CASE)

    every { binaryMessenger.send(any(), any(), any()) } answers
        {
          val codec = EnumApi2Flutter.codec
          val message = arg<ByteBuffer>(1)
          val reply = arg<BinaryMessenger.BinaryReply>(2)
          message.position(0)
          val args = codec.decodeMessage(message) as ArrayList<*>
          val replyData = codec.encodeMessage(args)
          replyData?.position(0)
          reply.reply(replyData)
        }

    var didCall = false
    api.echo(input) {
      didCall = true
      assertEquals(input, it.getOrNull())
    }

    assertTrue(didCall)
  }
}
