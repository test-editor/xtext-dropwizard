package org.testeditor.web.xtext.index.changes

import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.junit.Test
import org.mockito.ArgumentCaptor
import org.testeditor.web.xtext.index.SetBasedChangedResources

import static org.assertj.core.api.Assertions.assertThat
import static org.mockito.ArgumentMatchers.*
import static org.mockito.Mockito.mock
import static org.mockito.Mockito.never
import static org.mockito.Mockito.spy
import static org.mockito.Mockito.verify

class ChainableChangeDetectorTest {

	@Test
	def void proceedsWithNextDetectorInChain() {
		// given
		val mockResourceSet = mock(ResourceSet)
		val String[] paths = #[]
		val modifiedUriFromFirstDetector = URI.createFileURI('samplefile')
		val secondDetector = spy(new ChainableChangeDetectorForTesting([false], null))
		val firstDetector = new ChainableChangeDetectorForTesting([
			modifiedResources += modifiedUriFromFirstDetector
			return true
		], secondDetector)

		// when
		firstDetector.detectChanges(mockResourceSet, paths)

		// then
		val changedResourcesCaptor = ArgumentCaptor.forClass(SetBasedChangedResources)
		verify(secondDetector).handleChangeDetectionRequest(eq(mockResourceSet), eq(paths), changedResourcesCaptor.capture)
		assertThat(changedResourcesCaptor.value.modifiedResources).containsOnly(modifiedUriFromFirstDetector)
	}

	@Test
	def void returnsAccumulatedResult() {
		// given
		val mockResourceSet = mock(ResourceSet)
		val String[] paths = #[]
		val modifiedUriFromFirstDetector = URI.createFileURI('detected.first')
		val modifiedUriFromSecondDetector = URI.createFileURI('detected.later')

		val secondDetector = new ChainableChangeDetectorForTesting([
			modifiedResources += modifiedUriFromSecondDetector
			return false
		], null)
		val firstDetector = new ChainableChangeDetectorForTesting([
			modifiedResources += modifiedUriFromFirstDetector
			return true
		], secondDetector)

		// when
		val actual = firstDetector.detectChanges(mockResourceSet, paths)

		// then
		assertThat(actual.modifiedResources).containsOnly(#[modifiedUriFromFirstDetector, modifiedUriFromSecondDetector])
	}

	@Test
	def void stopsChainWhenFalseIsReturned() {
		// given
		val mockResourceSet = mock(ResourceSet)
		val String[] paths = #[]
		val secondDetector = spy(new ChainableChangeDetectorForTesting([false], null))
		val firstDetector = new ChainableChangeDetectorForTesting([false], secondDetector)

		// when
		firstDetector.detectChanges(mockResourceSet, paths)

		// then
		verify(secondDetector, never).handleChangeDetectionRequest(any, any, any)
	}

	@Test
	def void stopsChainWhenSuccessorIsNull() {
		// given
		val mockResourceSet = mock(ResourceSet)
		val String[] paths = #[]
		val modifiedUriFromFirstDetector = URI.createFileURI('samplefile')
		val firstDetector = new ChainableChangeDetectorForTesting([
			modifiedResources += modifiedUriFromFirstDetector
			return true
		], null)

		// when
		val actual = firstDetector.detectChanges(mockResourceSet, paths)

		// then
		assertThat(actual.modifiedResources).containsOnly(modifiedUriFromFirstDetector)
	}

}
