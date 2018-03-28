package org.testeditor.web.xtext.index

import com.google.common.base.Supplier
import com.google.inject.Inject
import java.io.File
import java.util.Set
import javax.inject.Named
import javax.inject.Provider
import javax.inject.Singleton
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.build.BuildRequest
import org.eclipse.xtext.build.IncrementalBuilder
import org.eclipse.xtext.build.IncrementalBuilder.Result
import org.eclipse.xtext.build.IndexState
import org.eclipse.xtext.resource.IResourceDescriptionsProvider
import org.eclipse.xtext.resource.IResourceServiceProvider
import org.eclipse.xtext.resource.XtextResourceSet
import org.eclipse.xtext.resource.impl.ChunkedResourceDescriptions
import org.eclipse.xtext.resource.impl.ProjectDescription
import org.eclipse.xtext.resource.impl.ResourceDescriptionsData
import org.eclipse.xtext.validation.CheckMode
import org.testeditor.web.dropwizard.xtext.XtextConfiguration
import org.testeditor.web.dropwizard.xtext.validation.ValidationMarkerUpdater

import static com.google.common.base.Suppliers.memoize

@Singleton
class BuildCycleManager {

	@Inject Provider<XtextConfiguration> config
	@Inject ChangeDetector changeDetector
	@Inject ValidationMarkerUpdater validationUpdater
	@Inject IncrementalBuilder builder
	@Inject ChunkedResourceDescriptionsProvider resourceDescriptionsProvider
	@Inject extension IndexSearchPathProvider searchPathProvider
	@Inject extension IResourceServiceProvider.Registry resourceServiceProviderFactory

	var Supplier<URI> baseURI = memoize[URI.createFileURI(config.get.localRepoFileRoot)]

	var IndexState lastIndexState = new IndexState
	var String[] staticSearchPaths = null

	var ChangedResources currentChanges

	def void startBuild() {
		val initialBuild = resourceDescriptionsProvider.resourceDescriptionsData === null

		val buildRequest = createBuildRequest.addChanges

		if (initialBuild) {
			buildRequest.build => [
				indexState.updateIndex
				buildRequest.state = indexState
			]
		}

		buildRequest => [
			build => [
				indexState.updateIndex
				affectedResources.filter[getNew !== null].map[uri].forEach[validate]
				affectedResources.filter[getNew === null].map[uri].forEach[removeValidationMarkers]
				updateValidationMarkers
			]
		]
	}

	def void validate(URI resourceURI) {
		val resourceValidator = getResourceServiceProvider(resourceURI).getResourceValidator
		if (resourceValidator !== null) {
			val resourceSet = resourceDescriptionsProvider.indexResourceSet
			val validationResult = resourceValidator.validate(resourceSet.getResource(resourceURI, true), CheckMode.ALL, null)
			validationUpdater.afterValidate(resourceURI, validationResult)
		}
	}

	def void removeValidationMarkers(URI resourceURI) {
		validationUpdater.afterValidate(resourceURI, emptyList)
	}

	def BuildRequest addChanges(BuildRequest request) {
		val baseDir = new File(config.get.localRepoFileRoot)
		val initialChanges = new ChangedResources => [
			classPath += config.get.indexClassPath.map[new File(baseDir, it).absolutePath]
		]
		return request => [
			val changes = changeDetector.detectChanges(resourceDescriptionsProvider.indexResourceSet, searchPaths, initialChanges)
			dirtyFiles += changes.modifiedResources
			deletedFiles += changes.deletedResources
			currentChanges = changes
		]
	}

	def String[] getSearchPaths() {
		return getStaticSearchPaths + config.get.localRepoFileRoot.additionalSearchPaths
	}

	def BuildRequest createBuildRequest() {
		return new BuildRequest => [
			baseDir = baseURI.get
			afterValidate = validationUpdater
			resourceSet = resourceDescriptionsProvider.indexResourceSet
			state = lastIndexState
			indexOnly = true
		]
	}

	def Result build(BuildRequest request) {
		return builder.build(request, [getResourceServiceProvider])
	}

	def void updateValidationMarkers() {
		validationUpdater.updateMarkerMap
	}

	def void updateIndex(IndexState indexState) {
		val projectName = resourceDescriptionsProvider.project.name
		val index = resourceDescriptionsProvider.resourceDescriptions

		index.setContainer(projectName, indexState.resourceDescriptions)
		lastIndexState = indexState
	}

	private def getStaticSearchPaths() {
		if (staticSearchPaths === null) {
			val baseDir = new File(config.get.localRepoFileRoot)
			staticSearchPaths = config.get.indexSearchPaths.map[new File(baseDir, it).absolutePath]
		}
		return staticSearchPaths
	}

}

@Singleton
class ChunkedResourceDescriptionsProvider implements IResourceDescriptionsProvider {

	public static val String PROJECT_NAME = 'projectName'

	@Accessors(PUBLIC_GETTER)
	XtextResourceSet indexResourceSet

	@Inject(optional=true)
	@Named(PROJECT_NAME)
	String projectName

	@Inject
	new(XtextResourceSet indexResourceSet) {
		this.indexResourceSet = indexResourceSet
	}

	var Supplier<ProjectDescription> project = memoize[
		new ProjectDescription => [
			name = projectName ?: 'Unnamed Project'
		]
	]

	def ProjectDescription getProject() {
		indexResourceSet.registerWithProject
		return project.get
	}

	def ResourceDescriptionsData getResourceDescriptionsData() {
		return resourceDescriptions.getContainer(getProject.name)
	}

	def ChunkedResourceDescriptions getResourceDescriptions() {
		var index = ChunkedResourceDescriptions.findInEmfObject(indexResourceSet)
		if (index === null) {
			indexResourceSet.registerWithProject
			index = new ChunkedResourceDescriptions(emptyMap, indexResourceSet)
		}
		return index
	}

	/**
	 * Get the resource descriptions (i.e. the content of the index) maintained by
	 * {@link BuildCycleManager BuildCycleManager}.
	 * 
	 * This class uses a fixed resource set which is associated with its index.
	 * If a different resource set is passed in, a shallow copy of the index is
	 * returned, registered with the given resource set (either a previously
	 * registered index, or, if none is found, a newly copied and registered
	 * instance).
	 * Note that the same resource descriptions instance can only be associated
	 * with a single resource set, which is why the copying is necessary.
	 */
	override ChunkedResourceDescriptions getResourceDescriptions(ResourceSet resourceSet) {
		return if (resourceSet !== indexResourceSet) {
			resourceSet.registerWithProject
			ChunkedResourceDescriptions.findInEmfObject(indexResourceSet) ?: resourceDescriptions.createShallowCopyWith(resourceSet)
		} else {
			resourceDescriptions
		}
	}

	private def registerWithProject(ResourceSet resourceSet) {
		if (ProjectDescription.findInEmfObject(resourceSet) === null) {
			project.get.attachToEmfObject(resourceSet)
		}
	}

}

interface IndexSearchPathProvider {

	def String[] additionalSearchPaths(String rootPath)

}

interface ChangeDetector {

	def ChangedResources detectChanges(ResourceSet resourceSet, String[] paths, ChangedResources accumulatedChanges)

}

@Accessors(PUBLIC_GETTER)
class ChangedResources {

	val Set<URI> modifiedResources = newHashSet
	val Set<URI> deletedResources = newHashSet
	val Set<String> classPath = newHashSet

}
