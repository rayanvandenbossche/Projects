declare module "adm-zip" {
  interface AdmZipEntry {
    isDirectory: boolean;
    entryName: string;
    getData(): Buffer;
  }

  export default class AdmZip {
    constructor(input?: Buffer | string);
    getEntries(): AdmZipEntry[];
    getEntry(entryName: string): AdmZipEntry | null;
  }
}