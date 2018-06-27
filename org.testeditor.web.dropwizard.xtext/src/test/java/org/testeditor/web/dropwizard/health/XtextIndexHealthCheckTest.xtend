package org.testeditor.web.dropwizard.health

import org.eclipse.xtext.resource.impl.ChunkedResourceDescriptions
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.InjectMocks
import org.mockito.Mock
import org.mockito.junit.MockitoJUnitRunner
import org.testeditor.web.xtext.index.ChunkedResourceDescriptionsProvider

import static org.assertj.core.api.Assertions.assertThat
import static org.mockito.ArgumentMatchers.*
import static org.mockito.Mockito.mock
import static org.mockito.Mockito.when

@RunWith(MockitoJUnitRunner)
class XtextIndexHealthCheckTest {
	@Mock ChunkedResourceDescriptionsProvider mockIndex
	@InjectMocks XtextIndexHealthCheck healthCheckUnderTest
	
	@Test
	def void reportsHealthyWhenIndexIsNotEmpty() {
		// given
		val mockResourceDescriptions = mock(ChunkedResourceDescriptions)
		when(mockIndex.getResourceDescriptions(any)).thenReturn(mockResourceDescriptions)
		when(mockResourceDescriptions.isEmpty).thenReturn(false)
		
		// when
		val actualResult = healthCheckUnderTest.check
		
		// then
		assertThat(actualResult.healthy).isTrue
	}
	
	@Test
	def void reportsUnhealthyWhenIndexIsEmpty() {
		// given
		val mockResourceDescriptions = mock(ChunkedResourceDescriptions)
		when(mockIndex.getResourceDescriptions(any)).thenReturn(mockResourceDescriptions)
		when(mockResourceDescriptions.isEmpty).thenReturn(true)
		
		// when
		val actualResult = healthCheckUnderTest.check
		
		// then
		assertThat(actualResult.healthy).isFalse
	}
}
