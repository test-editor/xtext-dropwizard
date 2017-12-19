package org.testeditor.web.xtext.index.persistence

import com.google.common.annotations.VisibleForTesting
import java.io.File
import java.util.List
import javax.inject.Singleton
import org.eclipse.jgit.api.Git
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.lib.ObjectId
import org.eclipse.jgit.treewalk.CanonicalTreeParser
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory

import static org.eclipse.jgit.lib.ConfigConstants.CONFIG_KEY_URL
import static org.eclipse.jgit.lib.ConfigConstants.CONFIG_REMOTE_SECTION
import static org.eclipse.jgit.lib.Constants.*

/**
 * provide some service around a git repo (read only)
 */
@Singleton
class GitService {

	static val logger = LoggerFactory.getLogger(GitService)

	@Accessors(PROTECTED_GETTER)
	@VisibleForTesting
	Git git

	@Accessors(PUBLIC_GETTER)
	File projectFolder

	/** 
	 * initialize this git service. either open the existing git and pull, or clone the remote repo
	 */
	def void init(String localRepoFileRoot, String remoteRepoUrl) {
		logger.info("Initializing with localRepoFileRoot='{}', remoteRepoUrl='{}'.", localRepoFileRoot, remoteRepoUrl)
		projectFolder = verifyIsFolderOrNonExistent(localRepoFileRoot)
		if (isExistingGitRepository(projectFolder)) {
			openRepository(projectFolder, remoteRepoUrl)
			pull
		} else {
			cloneRepository(projectFolder, remoteRepoUrl)
		}
	}

	private def File verifyIsFolderOrNonExistent(String localRepoFileRoot) {
		val file = new File(localRepoFileRoot)
		val existsButIsNotAFolder = file.exists && !file.isDirectory
		if (existsButIsNotAFolder) {
			val message = '''Configured localRepoFileRoot=«localRepoFileRoot» is not a directory!'''
			throw new IllegalArgumentException(message)
		}
		return file
	}

	@VisibleForTesting
	protected def boolean isExistingGitRepository(File folder) {
		return folder.exists && new File(folder, DOT_GIT).exists
	}

	def void pull() {
		git.pull.call
	}

	def ObjectId getHeadTree() {
		return git.repository.resolve('HEAD^{tree}')
	}

	/** 
	 * calculate diff between these two commits
	 */
	def List<DiffEntry> calculateDiff(String oldHeadCommit, String newHeadCommit) {
		return calculateDiff(ObjectId.fromString(oldHeadCommit), ObjectId.fromString(newHeadCommit))
	}

	private def List<DiffEntry> calculateDiff(ObjectId oldHead, ObjectId newHead) {
		logger.info("Calculating diff between old='{}' and new='{}'.", oldHead.getName, newHead.getName)
		val reader = git.repository.newObjectReader
		try {
			val oldTree = new CanonicalTreeParser => [reset(reader, oldHead)]
			val newTree = new CanonicalTreeParser => [reset(reader, newHead)]
			val diff = git.diff.setOldTree(oldTree).setNewTree(newTree).call
			logger.info("Calculated diff='{}'.", diff)
			return diff
		} finally {
			reader.close
		}
	}

	private def void cloneRepository(File projectFolder, String remoteRepoUrl) {
		git = Git.cloneRepository.setDirectory(projectFolder).setURI(remoteRepoUrl).call
	}

	@VisibleForTesting
	protected def void openRepository(File projectFolder, String remoteRepoUrl) {
		git = Git.open(projectFolder)
		verifyRemoteOriginMatches(remoteRepoUrl)
	}

	private def void verifyRemoteOriginMatches(String configuredRemoteRepoUrl) {
		val currentRemoteUrl = getRemoteUrl()
		if (currentRemoteUrl != configuredRemoteRepoUrl) {
			val message = '''
				The currently existing Git repository remote URL does not match the configured one.
					repository location: «git.repository.directory»
					remote origin: «currentRemoteUrl»
					remote origin as per configuration: «configuredRemoteRepoUrl» 
			'''
			throw new IllegalArgumentException(message)
		}
	}

	private def String getRemoteUrl() {
		val config = git.repository.config
		return config.getString(CONFIG_REMOTE_SECTION, DEFAULT_REMOTE_NAME, CONFIG_KEY_URL)
	}

}
