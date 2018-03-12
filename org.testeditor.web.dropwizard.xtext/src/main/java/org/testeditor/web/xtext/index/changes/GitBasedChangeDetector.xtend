package org.testeditor.web.xtext.index.changes

import com.google.inject.Inject
import java.io.File
import javax.inject.Named
import javax.inject.Singleton
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory
import org.testeditor.web.xtext.index.SetBasedChangedResources
import org.testeditor.web.xtext.index.persistence.GitService

@Singleton
class GitBasedChangeDetector extends ChainableChangeDetector {

	static val logger = LoggerFactory.getLogger(GitBasedChangeDetector)
	public static val String SUCCESSOR_NAME = 'GitBasedChangeDetectorSuccessor'

	@Inject GitService git
	@Inject extension IndexFilter indexFilter

	@Accessors(PUBLIC_GETTER)
	@Inject(optional=true)
	@Named(SUCCESSOR_NAME)
	ChainableChangeDetector successor

	var String lastUpdatedAtRevision = null

	override protected handleChangeDetectionRequest(ResourceSet resourceSet, String[] paths, SetBasedChangedResources detectedChanges) {
		val root = git.projectFolder
		pullAndGetDiff.filter[isRelevantAndContainedIn(paths)].fold(detectedChanges, [ changedResources, diff |
			changedResources.handleRelevantDiff(diff, root, resourceSet)
		])
		return successor !== null
	}

	private def isRelevantAndContainedIn(DiffEntry diff, String[] searchPaths) {
		val relevantPath = diff.relevantPath
		return relevantPath !== null && relevantPath.isContainedIn(searchPaths)
	}

	private def String getRelevantPath(DiffEntry diff) {
		val root = git.projectFolder
		val absoluteOldPath = diff.oldPath?.toAbsolutePath(root)
		val absoluteNewPath = diff.newPath?.toAbsolutePath(root)

		return if (absoluteOldPath.isRelevantForIndex) {
			absoluteOldPath
		} else if (absoluteNewPath.isRelevantForIndex) {
			absoluteNewPath
		} else {
			null
		}
	}

	private def isContainedIn(String path, String[] searchPaths) {
		return searchPaths.exists[path.startsWith(it)]
	}

	private def toAbsolutePath(String path, File root) {
		return new File(root, path).absolutePath
	}

	private def pullAndGetDiff() {
		val oldHead = lastUpdatedAtRevision
		git.pull
		lastUpdatedAtRevision = git.headTree.name()
		return if (oldHead === null) {
			git.allFilesAsDiff(lastUpdatedAtRevision)
		} else {
			git.calculateDiff(oldHead, lastUpdatedAtRevision)
		}
	}

	private def SetBasedChangedResources handleRelevantDiff(SetBasedChangedResources changedResources, DiffEntry diff, File root,
		ResourceSet resourceSet) {
		logger.debug("Handling Git diff='{}'.", diff)
		return changedResources => [
			switch (diff.changeType) {
				case ADD,
				case MODIFY: {
					modifiedResources += getAbsoluteFileURI(root, diff.newPath)
				}
				case COPY: {
					if (diff.newPath.isRelevantForIndex) {
						modifiedResources += getAbsoluteFileURI(root, diff.newPath)
					} else {
						logger.debug("Skipping index update for irrelevant diff='{}'.", diff)
					}
				}
				case DELETE: {
					deletedResources += getAbsoluteFileURI(root, diff.oldPath)
				}
				case RENAME: {
					if (diff.oldPath.isRelevantForIndex) {
						deletedResources += getAbsoluteFileURI(root, diff.oldPath)
					}
					if (diff.newPath.isRelevantForIndex) {
						modifiedResources += getAbsoluteFileURI(root, diff.newPath)
					}
				}
				default: {
					throw new RuntimeException('''Unknown Git diff change type='«diff.changeType.name»'.''')
				}
			}
		]
	}

	private def URI getAbsoluteFileURI(File file) {
		return URI.createFileURI(file.absolutePath)
	}

	private def URI getAbsoluteFileURI(File parent, String child) {
		val file = new File(parent, child)
		return getAbsoluteFileURI(file)
	}

}
