import 'dotenv/config'
import { SuperfaceClient } from '@superfaceai/one-sdk'
import filenamify from 'filenamify'
import { writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import config from './config.js'

const sdk = new SuperfaceClient()

async function* paginated(perform, limit = Infinity) {
  let nextPage = undefined
  let i = 0
  do {
    console.error(`Page ${i}`)
    const result = await perform(nextPage)
    if (result.isErr()) {
      throw result.error
    } else {
      nextPage = result.value.nextPage
      yield result.value
    }
    i++
  } while (nextPage != null && i < limit)
}

async function saveFile(data, id) {
  const fName = filenamify(id, { replacement: '-' })
  const pathName = join(config.outputDir, `${fName}.json`)
  return writeFile(pathName, JSON.stringify(data, undefined, 2), {
    encoding: 'utf8',
  })
}

async function saveResource(useCase) {
  const profile = await sdk.getProfile('get-bookmarks')

  const results = paginated((page) =>
    profile.getUseCase(useCase).perform({ page })
  )

  for await (const result of results) {
    // console.log(JSON.stringify(result))
    if (result.data?.length) {
      await saveFile(result.data, result.self)
    }
  }
}

console.error('Fetching bookmarks...')
await saveResource('GetPosts')

console.error('Fetching comments...')
await saveResource('GetComments')
