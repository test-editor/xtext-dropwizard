/*******************************************************************************
 * Copyright (c) 2012 - 2017 Signal Iduna Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 * Signal Iduna Corporation - initial API and implementation
 * akquinet AG
 * itemis AG
 *******************************************************************************/

package org.testeditor.web.xtext.index.resources.bitbucket

import com.fasterxml.jackson.databind.ObjectMapper
import org.junit.Test
import org.testeditor.web.xtext.index.resources.RepoEvent
import org.testeditor.web.xtext.index.resources.RepoEventCallback

import static extension org.mockito.Mockito.mock
import static extension org.mockito.Mockito.verify

class BitbucketWebhookTest {

	val callbackMock = RepoEventCallback.mock
	val pushHandler = new Push => [callback = callbackMock]

	@Test
	def void pushJson_callbackCalled() {
		// given
		val expectedUser = 'John Difool'
		val jsonString = '''
		{
			"actor": { "username": "«expectedUser»" },
			"repository" : { },
			"push": { }
		}'''
		val json = new ObjectMapper().readTree(jsonString)
		val expectedEvent = new RepoEvent(expectedUser, json)

		// when
		pushHandler.runPush(jsonString)

		// then
		callbackMock.verify.call(expectedEvent)
	}
}
