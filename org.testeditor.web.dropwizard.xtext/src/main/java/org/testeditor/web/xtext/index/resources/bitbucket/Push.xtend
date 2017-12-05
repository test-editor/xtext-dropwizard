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

import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import javax.ws.rs.Consumes
import javax.ws.rs.POST
import javax.ws.rs.Path
import javax.ws.rs.core.MediaType
import javax.ws.rs.core.Response
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory
import org.testeditor.web.xtext.index.resources.RepoEvent
import org.testeditor.web.xtext.index.resources.RepoEventCallback

import static javax.ws.rs.core.Response.Status.*
import static javax.ws.rs.core.Response.status

/**
 * Endpoint for BitBucket Webhook Push Events.
 * 
 * Payload see https://confluence.atlassian.com/bitbucket/event-payloads-740262817.html 
 */
@Path("/xtext/index/webhook/bitbucket/push")
@Consumes(MediaType.APPLICATION_JSON)
class Push {
	
	static val logger = LoggerFactory.getLogger(Push);
	
	@Accessors(PUBLIC_SETTER)
	var RepoEventCallback callback

	/**
	 * Bitbucket WebHook Push Endpoint
	 */
	@POST
	def Response push(String payload) {
		var resultStatusBuilder = status(NO_CONTENT)
		logger.info("Push.push received with payload='{}'", payload)
		try {
			val pushSucceeded = runPush(payload)
			if (!pushSucceeded) {
				resultStatusBuilder = status(INTERNAL_SERVER_ERROR)
			}
		} catch (Exception e) {
			logger.error("push event of unexpected (json) format", e)
			resultStatusBuilder = status(BAD_REQUEST)
		}

		return resultStatusBuilder.build
	}
	
	def boolean runPush(String payload) {
		val objectMapper = new ObjectMapper
		val node = objectMapper.readValue(payload, JsonNode)
		val actorNode = node.get("actor")
		val username = actorNode.get("username").asText
		val reportEvent = new RepoEvent(username, node)

		return guardedInformListener(reportEvent)
	}

	/**
	 * Report repository event to listener and return whether this succeeded (true) or failed (false)
	 */
	private def boolean guardedInformListener(RepoEvent event) {
		try {
			callback?.call(event)
		} catch (Exception e) {
			logger.error("push event callback failed", e)
			return false
		}
		return true
	}

}
