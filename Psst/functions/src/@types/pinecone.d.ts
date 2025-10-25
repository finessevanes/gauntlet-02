declare module '@pinecone-database/pinecone' {
  export class Pinecone {
    constructor(config: any);
    index(indexName: string): any;
  }
}
