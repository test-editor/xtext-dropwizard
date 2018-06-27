package org.testeditor.web.dropwizard.health

import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.InjectMocks
import org.mockito.Mock
import org.mockito.junit.MockitoJUnitRunner
import org.testeditor.web.xtext.index.persistence.GitService

import static org.assertj.core.api.Assertions.assertThat
import static org.mockito.Mockito.when

@RunWith(MockitoJUnitRunner)
class GitHealthCheckTest {
	@Mock GitService mockGit
	@InjectMocks GitHealthCheck healthCheckUnderTest
	
	@Test
	def void reportsHealthyWhenWorkingCopyIsConflictFree() {
		// given
		when(mockGit.conflicts).thenReturn(emptySet)
		
		// when
		val actualResult = healthCheckUnderTest.check
		
		// then
		assertThat(actualResult.healthy).isTrue
	}
	
	@Test
	def void reportsUnhealthyWhenIndexIsEmpty() {
		// given
		when(mockGit.conflicts).thenReturn(#{'aFileInConflict'})
		
		// when
		val actualResult = healthCheckUnderTest.check
		
		// then
		assertThat(actualResult.healthy).isFalse
	}
}
