package org.testeditor.web.xtext.index

import org.eclipse.emf.common.util.URI
import org.eclipse.xtext.build.BuildRequest
import org.eclipse.xtext.build.IncrementalBuilder
import org.eclipse.xtext.build.IndexState
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.resource.impl.ChunkedResourceDescriptions
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData
import org.eclipse.xtext.resource.persistence.SerializableEObjectDescription
import org.eclipse.xtext.xbase.lib.Functions.Function1
import org.junit.Before
import org.junit.Test
import org.mockito.ArgumentCaptor
import org.mockito.InjectMocks
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.testeditor.web.dropwizard.xtext.validation.ValidationMarkerUpdater

import static org.assertj.core.api.Assertions.assertThat
import static org.mockito.ArgumentMatchers.*
import static org.mockito.Mockito.mock
import static org.mockito.Mockito.verify
import static org.mockito.Mockito.when

class BuildCycleManagerTest {

	@Mock ChangeDetector mockChangeDetector
	@Mock XtextResourceSet mockResourceSet
	@Mock ValidationMarkerUpdater mockValidationMarkerUpdater
	@Mock IncrementalBuilder mockIncrementalBuilder
	@Mock extension IResourceServiceProvider.Registry mockResourceServiceProviderRegistry
	@Mock ChunkedResourceDescriptionsProvider indexProvider
	@Mock ChunkedResourceDescriptions index
	@InjectMocks extension BuildCycleManager unitUnderTest

	val expectedModifiedResources = #[URI.createFileURI('/path/to/modified/resource')]
	val expectedDeletedResource = #[URI.createFileURI('/path/to/deleted/resource')]
	val initialIndexState = new IndexState

	var BuildRequest sampleBuildRequest

	@Before
	def void setupChangeDetectorMock() {
		MockitoAnnotations.initMocks(this)

		sampleBuildRequest = new BuildRequest => [
			baseDir = URI.createFileURI('/base/dir')
			resourceSet = mockResourceSet
			afterValidate = mockValidationMarkerUpdater
			deletedFiles = expectedDeletedResource
			dirtyFiles = expectedModifiedResources
			state = initialIndexState
		]

		when(mockChangeDetector.modifiedResources).thenReturn(expectedModifiedResources)
		when(mockChangeDetector.deletedResources).thenReturn(expectedDeletedResource)

		val builderResult = mock(IncrementalBuilder.Result)
		val indexState = getMockedIndexState(#['Test'])
		when(builderResult.indexState).thenReturn(indexState)
		when(mockIncrementalBuilder.build(eq(sampleBuildRequest), any)).thenAnswer [
			<BuildRequest>getArgument(0).afterValidate.afterValidate(null, null)
			builderResult
		]

		when(indexProvider.getIndex(mockResourceSet)).thenReturn(index)
	}

	private def getMockedIndexState(Iterable<String> eObjectNames) {
		val indexState = mock(IndexState)
		val resourceDescriptionsData = mock(ResourceDescriptionsData)
		when(resourceDescriptionsData.exportedObjects).thenReturn(
			eObjectNames.map [ eObjectName |
			val desc = new SerializableEObjectDescription()
			desc.qualifiedName = QualifiedName.create(eObjectName)
			return desc
		])
		when(indexState.resourceDescriptions).thenReturn(resourceDescriptionsData)
		return indexState
	}

	@Test
	def void detectChangesReturnsModifiedFiles() {
		// given
		val initialBuildRequest = new BuildRequest

		// when
		val actualBuildRequest = initialBuildRequest.addChanges

		// then
		assertThat(actualBuildRequest.deletedFiles).containsOnly(expectedDeletedResource)
		assertThat(actualBuildRequest.dirtyFiles).containsOnly(expectedModifiedResources)
	}

	@Test
	def void createBuildRequestSetsRequiredFields() {
		// given
		unitUnderTest.init(URI.createFileURI('/base/dir'))

		// when
		val actualBuildRequest = unitUnderTest.createBuildRequest

		// then
		assertThat(actualBuildRequest.baseDir).isEqualTo(URI.createFileURI('/base/dir'))
		assertThat(actualBuildRequest.resourceSet).isEqualTo(mockResourceSet)
		assertThat(actualBuildRequest.afterValidate).isEqualTo(mockValidationMarkerUpdater)
		assertThat(actualBuildRequest.state.getResourceDescriptions.exportedObjects).isEmpty
	}

	@Test
	def void createBuildRequestAlwaysUsesSameResourceSet() {
		// given
		val firstBuildRequest = unitUnderTest.createBuildRequest

		// when
		val secondBuildRequest = unitUnderTest.createBuildRequest

		// then
		assertThat(firstBuildRequest.resourceSet).isSameAs(secondBuildRequest.resourceSet)
	}

	@Test
	def void launchReturnsUpdatedIndexState() {
		// given
		val buildRequest = sampleBuildRequest
		// when
		val actualIndexState = unitUnderTest.build(buildRequest)

		// then
		assertThat(actualIndexState.resourceDescriptions.exportedObjects.head.qualifiedName.toString).isEqualTo('Test')
	}

	@Test
	def void launchInvokesValidationMarkerUpdaterState() {
		// given
		val buildRequest = sampleBuildRequest
		// when
		unitUnderTest.build(buildRequest)

		// then
		verify(mockValidationMarkerUpdater).afterValidate(any, any)
	}

	@Test
	def void launchInvokesBuilderWithResourceServiceRegistry() {
		// given
		val buildRequest = sampleBuildRequest
		val resourceServiceRegistryCaptor = ArgumentCaptor.forClass(Function1)
		// when
		unitUnderTest.build(buildRequest)

		// then
		verify(mockIncrementalBuilder).build(eq(sampleBuildRequest), resourceServiceRegistryCaptor.capture)
		val testURI = URI.createFileURI('test')
		resourceServiceRegistryCaptor.value.apply(testURI)
		verify(mockResourceServiceProviderRegistry).getResourceServiceProvider(testURI)
	}

	@Test
	def void updateValidationMarkersInvokesUpdateMarkerMap() {
		// when
		unitUnderTest.updateValidationMarkers

		// then
		verify(mockValidationMarkerUpdater).updateMarkerMap
	}

	@Test
	def void updateIndexPublishesNewIndexState() {
		// given
		val exportedObjectNames = #['modelElement', 'anotherElement']
		val newIndexState = getMockedIndexState(exportedObjectNames)
		val baseURI = URI.createFileURI('/base/dir')
		unitUnderTest.init(baseURI)

		// when
		unitUnderTest.updateIndex(newIndexState)

		// then
		verify(index).setContainer(baseURI.toString, newIndexState.resourceDescriptions)
	}

}
