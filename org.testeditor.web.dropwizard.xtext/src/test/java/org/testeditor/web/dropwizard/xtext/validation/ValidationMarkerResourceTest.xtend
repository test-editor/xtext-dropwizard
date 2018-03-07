package org.testeditor.web.dropwizard.xtext.validation

import java.util.concurrent.TimeoutException
import javax.inject.Provider
import javax.ws.rs.container.AsyncResponse
import javax.ws.rs.core.Response
import javax.ws.rs.core.Response.ResponseBuilder
import org.junit.Before
import org.junit.Test
import org.mockito.ArgumentCaptor
import org.mockito.InjectMocks
import org.mockito.Mock
import org.testeditor.web.xtext.index.AbstractTestWithExampleLanguage

import static javax.ws.rs.core.Response.Status.NO_CONTENT
import static javax.ws.rs.core.Response.Status.OK
import static org.assertj.core.api.Assertions.assertThat
import static org.mockito.ArgumentMatchers.any
import static org.mockito.ArgumentMatchers.anyLong
import static org.mockito.ArgumentMatchers.eq
import static org.mockito.ArgumentMatchers.nullable
import static org.mockito.Mockito.mock
import static org.mockito.Mockito.never
import static org.mockito.Mockito.verify
import static org.mockito.Mockito.when

class ValidationMarkerResourceTest extends AbstractTestWithExampleLanguage {

	@Mock ValidationMarkerMap markerMap
	@Mock Provider<ResponseBuilder> responseBuilderProvider
	@Mock ResponseBuilder responseBuilder
	@Mock Response dummyResponse
	@InjectMocks ValidationMarkerResource unitUnderTest

	val expectedSummaries = #[
		new ValidationSummary('path', 1, 2, 3),
		new ValidationSummary('different/path', 6, 5, 4)
	]
	val unknownPath = 'unknown/path'

	@Before
	def void setUpMocks() {
		when(markerMap.allMarkers).thenReturn(expectedSummaries)

		when(markerMap.getMarker('path')).thenReturn(expectedSummaries.get(0))
		when(markerMap.getMarker('different/path')).thenReturn(expectedSummaries.get(1))
		when(markerMap.getMarker(unknownPath)).thenReturn(ValidationSummary.noMarkers(unknownPath))

		when(responseBuilderProvider.get).thenReturn(responseBuilder)
		when(responseBuilder.status(any)).thenReturn(responseBuilder)
		when(responseBuilder.entity(any)).thenReturn(responseBuilder)
		when(responseBuilder.header(any, any)).thenReturn(responseBuilder)
		when(responseBuilder.build).thenReturn(dummyResponse)
	}

	@Test
	def void retrievesValidationSummaryForGivenPath() {
		// given
		val resourcePath = 'path'

		// when
		val actualSummaries = unitUnderTest.getValidationMarkers(resourcePath)

		// then
		assertThat(actualSummaries).containsOnly(expectedSummaries.get(0))
	}

	@Test
	def void retrievesAllMarkersWhenNoPathIsGiven() {
		// given
		val resourcePath = null

		// when
		val actualSummaries = unitUnderTest.getValidationMarkers(resourcePath)

		// then
		assertThat(actualSummaries).containsExactlyInAnyOrder(expectedSummaries)
	}

	@Test
	def void returnsNoMarkersDefaultWhenPathIsNotFound() {
		// given
		val resourcePath = unknownPath

		// when
		val actualSummaries = unitUnderTest.getValidationMarkers(resourcePath)

		// then
		assertThat(actualSummaries).containsExactlyInAnyOrder(ValidationSummary.noMarkers(unknownPath))
	}

	@Test
	def void waitsForValidationUpdateAndReturnsAllSummaries() {
		// given
		val neverAccessed = -1L
		val mockResponse = mock(AsyncResponse)
		when(markerMap.waitForAnyNewMarkersSince(eq(neverAccessed), anyLong)).thenReturn(expectedSummaries)

		// when
		unitUnderTest.waitForValidationUpdates(mockResponse, neverAccessed)

		// then
		val actualEntity = ArgumentCaptor.forClass(Object);
		val actualStatus = ArgumentCaptor.forClass(Response.Status);

		verify(mockResponse).resume(dummyResponse)
		verify(responseBuilder).status(actualStatus.capture)
		verify(responseBuilder).entity(actualEntity.capture)

		assertThat(actualStatus.value).isEqualTo(OK)
		assertThat(actualEntity.value).isEqualTo(expectedSummaries)
	}

	@Test
	def void waitForValidationUpdatesReturnsNoContentOnTimeout() {
		// given
		val accessedInFuture = System.currentTimeMillis + 5000L
		val mockResponse = mock(AsyncResponse)
		when(markerMap.waitForAnyNewMarkersSince(eq(accessedInFuture), anyLong)).thenThrow(TimeoutException)

		// when
		unitUnderTest.waitForValidationUpdates(mockResponse, accessedInFuture)

		// then
		val actualStatus = ArgumentCaptor.forClass(Response.Status);

		verify(mockResponse).resume(dummyResponse)
		verify(responseBuilder).status(actualStatus.capture)
		verify(responseBuilder, never).entity(nullable(Object))

		assertThat(actualStatus.value).isEqualTo(NO_CONTENT)
	}

}
