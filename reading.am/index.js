import 'dotenv/config'
import { SuperfaceClient } from '@superfaceai/one-sdk'

const sdk = new SuperfaceClient()

async function fetchPosts() {
  const profile = await sdk.getProfile('get-bookmarks')

  const result = await profile.getUseCase('GetBookmarks').perform({})

  console.log(result.unwrap())
}

async function fetchComments() {}

await fetchPosts()
