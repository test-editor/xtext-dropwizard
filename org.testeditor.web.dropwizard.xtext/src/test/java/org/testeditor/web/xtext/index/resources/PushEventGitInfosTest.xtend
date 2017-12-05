package org.testeditor.web.xtext.index.resources

import com.fasterxml.jackson.databind.ObjectMapper
import javax.inject.Inject
import org.junit.Test
import org.testeditor.web.xtext.index.AbstractTestInjectingMembers

import static org.assertj.core.api.Assertions.*

class PushEventGitInfosTest extends AbstractTestInjectingMembers {

	@Inject PushEventGitInfos pushEventGitInfos

	@Test
	def void bitbucketPushExambleIsIdentifiedAsPush() {
		// given
		val json = new ObjectMapper().readTree(class.classLoader.getResourceAsStream("push-payload.bitbucket.json"))
		val event = new RepoEvent('', json)

		// when
		val isPushEvent = pushEventGitInfos.isPushEvent(event)

		// then
		assertThat(isPushEvent).isTrue
	}

	@Test
	def void invalidPushEventIsIdentifiedAsNonPushEvent() {
		// given
		val json = new ObjectMapper().readTree('''
		{ 
			"username": "", 
			"repo": { }, 
			"push": { 
				"changes": [ ]
			}
		}''')
		val event = new RepoEvent('', json)

		// when
		val isPushEvent = pushEventGitInfos.isPushEvent(event)

		// then
		assertThat(isPushEvent).isFalse
	}

	@Test
	def void commitIdsAreExtractedFromValidPushEvent() {
		// given
		val json = new ObjectMapper().readTree(class.classLoader.getResourceAsStream("push-payload.bitbucket.json"))
		val event = new RepoEvent('', json)

		// when
		val commitIds = pushEventGitInfos.getOldNewHeadCommitIds(event)

		// then
		commitIds => [
			assertThat(first).isEqualTo("6cbb8ba5f1eac5091a37522f1067d3a47a570f25")
			assertThat(second).isEqualTo("c8f6df595043a981fad690cff7bbfd42e86afcbf")
		]
	}

}
