# ChIP-Atlas / Documents
Documents for computational processing in ChIP-Atlas.
## Table of Contents
1. [Data source](#data_source_doc)
2. [Primary processing](#primary_processing_doc)
3. [Data Annotation](#data_annotation_doc)
4. [Peak Browser](#peak_browser_doc)
5. [Target Genes](#target_genes_doc)
6. [Colocalization](#colocalization_doc)
7. [in silico ChIP](#virtual_chip_doc)
8. [Downloads](#downloads_doc)

<a name="data_source_doc"></a>
## 1. Data source
Currently, most academic journals require that authors of studies including high-throughput sequencing must submit their raw sequence data as SRAs (Sequence Read Archives) to public repositories ([NCBI][NCBI], [DDBJ][DDBJ] or [ENA][ENA]). Each experiment is assigned an ID, called an experimental accession, beginning with SRX, DRX, or ERX (hereafter ‘[SRXs][SRX]’). To refer to corresponding ‘experiment’ and ‘biosample’ metadata in the XML format (available from [NCBI FTP site][NCBImeta]), ChIP-Atlas uses SRXs with the following criteria:

- LIBRARY STRATEGY == "ChIP-seq" or "DNase-Hypersensitivity"
- LIBRARY_SOURCE == "GENOMIC"
- INSTRUMENT_MODEL ~ "Illumina"  

![][dataNumber]



<a name="primary_processing_doc"></a>
## 2. Primary processing
###Introduction
Raw sequence data from SRXs as shown above were aligned to reference genomes with Bowtie2 before being analyzed for coverage in BigWig format and peak-calls in BED format.  
![][flowchart]

###Methods

1. Binarized sequence raw data (.sra) for each SRX were downloaded and decoded into Fastq format with the `fastq-dump` command of [SRA Toolkit][SraToolKit] (ver 2.3.2-4) with a default mode, except paired-end reads, which were decoded with the `--split-files` option. In an SRX including multiple runs, decoded Fastq files were concatenated into a single one.
2. Fastq files were then aligned with [Bowtie 2][bowtie2] (ver 2.2.2) with a default mode, except paired-end reads, for which two Fastq files were specified with `-1` and `-2` options. The following genome assemblies were used for the alignment and subsequent processing:

    - **hg19** (_H. sapiens_)
    - **mm9** (_M. musculus_)
    - **dm3** (_D. melanogaster_)
    - **ce10** (_C. elegans_)
    - **sacCer3** (_S. cerevisiae_)

3. Resultant SAM-formatted files were then binarized into BAM format with [SAMtools][samtools] (ver 0.1.19; `samtools view`) and sorted (`samtools sort`) before removing PCR duplicates (`samtools rmdup`).
4. BedGraph-formatted coverage scores were calculated with [bedtools][bedtools] (ver 2.17.0; `genomeCoverageBed`) in RPM (Reads Per Million mapped reads) units with `-scale 1000000/N` option, where N is mapped read counts after removing PCR duplicates as shown in section 3.
5. BedGraph files were binarized into BigWig format with [UCSC][UCSCtools]  `bedGraphToBigWig` tool (ver 4).
BAM files made in (3) were used to peak-call with [MACS2][MACS2] (ver 2.1.0; `macs2 callpeak`) in BED4 format. Options for _q_-value threshold were set (`-q 1e-05`, `1e-10`, or `1e-20`), with the options for genome sizes as follows:

    - hg19: `-g hs`
    - mm9: `-g mm`
    - dm3: `-g dm`
    - ce10: `-g ce`
    - sacCer3: `-g 12100000`

    Each row in the BED4 files includes the genomic location in the 1st to 3rd columns and MACS2 score (-10\*Log<sub>10</sub>[MACS2 *q*-value]) in the 4th column.
6. BED4 files were binarized into BigBed format with [UCSC][UCSCtools] `bedToBigBed` tool (ver 2.5).




<a name="data_annotation_doc"></a>
## 3. Data Annotation
###Introduction
Experimental materials used for each SRX were manually annotated to allow for extracting data via keywords for antigens and cell types.

###Methods

1. Sample metadata for all SRXs (biosample_set.xml) were downloaded from the [NCBI FTP site][NCBImeta] to extract the attributes for antigens and antibodies (see [here][ag_attributes]) as well as cell types and tissues (see [here][ct_attributes]).
2. According to the attribute values ascribed to each SRX, antigens and cell types used were manually annotated by curators who have been fully trained on molecular and developmental biology. Each annotation has a ‘Class’ and ‘Subclass’ as shown in **antigenList.tab** ([Download][antigenList], [Table schema](#antigenList_schema)) and **celltypeList.tab** ([Download][celltypeList], [Table schema](#celltypeList_schema)).
3.	Guidelines for antigens annotation:
    - **Histones**  
    Based on Brno nomenclature ([PMID: 15702071][PMID_15702071]).  
    (e.g., H3K4me3, H3K27ac)
    - **Gene-encoded proteins**
        + Gene symbols were recorded according to the following gene nomenclature databases:

            * [HGNC][HGNC] (*H. sapiens*)  
            * [MGI][MGI] (*M. musculus*)
            * [FlyBase][FlyBase] (*D. melanogaster*)
            * [WormBase][WormBase] (*C. elegans*)
            * [SGD][SGD] (*S. cerevisiae*)  
            (e.g., OCT3/4 → POU5F1; p53 → TP53)
        + Modifications such as phosphorylation were ignored.  
        (e.g., phospho-SMAD3 → SMAD3)
        + If an antibody recognizes multiple molecules in a family, the first in an ascending order was chosen.  
        (e.g., Anti-SMAD2/3 antibody → SMAD2)
4. Criteria for cell types annotation:
    - **_H. sapiens_ and _M. musculus_**  
      Cell types were mainly classified by the tissues derived from. ES and iPS cells were exceptionally classified in ‘Pluripotent stem cell’ class.


    | Cell-type class       | Cell type                        |
    |-----------------------|----------------------------------|
    | Blood                 | K-562; CD4-Positive T-Lymphocytes|
    | Breast                | MCF-7; T-47D                     |
    | Pluripotent stem cell | hESC H1; iPS cells               |


    - **_D. melanogaster_**  
      Cell types were mainly classified by cell lines and developmental stages.
    - **_C. elegans_**  
      Mainly classified by developmental stages.
    - **_S. cerevisiae_**  
      Classified by yeast strains.
    - **Standardized Nomenclatures**  
      Nomenclatures of cell lines and tissue names were standardized according to the following frameworks and resources:
        - Supplementary Table S2 in Yu et. al 2015 ([PMID: 25877200][PMID_25877200]), proposing unified cell-line names
        - [ATCC], a nonprofit repository of cell lines
        - [MeSH] \(Medical Subject Headings\) for tissue names
        - [FlyBase] for cell lines of *D. melanogaster*  
        (e.g., MDA-231, MDA231, MDAMB231 → MDA-MB-231)
5. Antigens or cell types were classified in ‘Uncategorized’ class if the curators could not understand attribute values.
6. Antigens or cell types were classified in ‘No description’ class if there was no attribute value.


<a name="peak_browser_doc"></a>
## 4. Peak Browser
ChIP-Atlas **Peak Browser** allows users to search for proteins bound to given genomic loci on the genome browser IGV. This is useful for predicting cis-regulatory elements, as well as to find regulatory proteins and the epigenetic status of given regions. BED4-formatted peak-call data from **2.5** were concatenated and converted to BED9 + GFF3 format to browse on genome browser IGV.

| Column     | Description                             | Example   |
|------------|-----------------------------------------|-----------|
| Header     | Track name and link URL                 | (Strings) |
| Column 1   | Chromosome                              | chr12     |
| Column 2   | Begin                                   | 1234      |
| Column 3   | End                                     | 5678      |
| Column 4*  | Sample metadata                         | (Strings) |
| Column 5   | -10Log<sub>10</sub>(MACS2 *q*-value)    | 345       |
| Column 6   | .                                       | .         |
| Column 7   | Begin (= Column 2)                      | 1234      |
| Column 8   | End (= Column 3)                        | 5678      |
| Column 9** | Color code                              | 255,61,0  |




- *Column 4  
  Sample metadata described in GFF3 format to show annotated antigens and cell types on IGV. Furthermore, mousing over a peak displays accession number, title, and all attribute values described in Biosample metadata for the SRX.
- **Column 9  
  Heatmap color codes for Column 5.  
  (If Column 5 is 0, 500, or 1000, then colors are blue, green, or red, respectively.)

<a name="target_genes_doc"></a>
## 5. Target Genes
###Introduction
The ChIP-Atlas **Target Genes** feature predicts genes directly regulated by given proteins, based on binding profiles of all public ChIP-seq data for particular gene loci. Target genes were accepted if the peak-call intervals of a given protein overlapped with a transcription start site (TSS) ± N kb (N = 1, 5, or 10).

###Methods

1. Peak-call data:  
  BED4-formatted peak-call data of each SRX made in section **2.5** were used (MACS2 *q*-value < 1E-05; antigen class = ‘TFs and others’).
2. Preparation of TSS library:  
  Location of TSSs and gene symbols were according to refFlat files (at [UCSC FTP site][UCSC_FTP]); only protein-coding genes were used for this analysis.
3. Preparation of STRING library:  
  [STRING][STRING] is a comprehensive database recording protein-protein and protein-gene interactions based on experimental evidence. A file describing all interactions was downloaded from [protein.actions.v10.txt.gz][STRING_DL], and the protein IDs were converted to gene symbols with  [protein.aliases.v10.txt.gz][STRING_DL].
4. Processing:  
  `bedtools window` command ([bedtools][bedtools] ver 2.17.0) was used to search target genes from peak-call data (**5.1**) from the TSS library (**5.2**) with a window size option (`-w 1000`, `5000`, or `10000`). Peak-call data of the same antigens were collected, and MACS2 scores (-10\*Log<sub>10</sub>[MACS2 *q*-value]) were indicated as heatmap colors on the web browser (MACS2 score = 0, 500, 1000 → color = blue, green, red) (see [example][tgSample]). If a gene intersected with multiple peaks of a single SRX, the highest MACS2 score was chosen for the color indication. The ‘Average’ column at the far left of the table shows the means of the MACS2 scores in the same row. The ‘STRING’ column on the far right indicates the STRING scores for the protein-gene interaction according to STRING library (**5.3**). For more details, protein-gene pairs in [protein.actions.v10.txt.gz][STRING_DL] file were extracted when meeting the following conditions:
    - 1st column (item\_id\_a) == Query antigen
    - 2nd column (item\_id\_b) == Target gene
    - 3rd column (mode) == "expression"
    - 5th column (a\_is\_acting) == "1"

<a name="colocalization_doc"></a>
## 6. Colocalization
###Introduction
Many transcription factors (TFs) form complexes to promote or enhance transcriptional activity (e.g., Pou5f1, Nanog, and Sox2 in mouse ES cells). ChIP-seq profiles of such TFs are often similar, showing colocalization on multiple genomic regions. The ChIP-Atlas **Colocalization** predicts colocalization partners of given TFs, evaluated through comprehensive and combinatorial similarity analyses of all public ChIP-seq data.

###Algorithms
BED4-formatted peak-call data made in section **2.5** were analyzed to evaluate the similarities to other peak-call data in identical cell-type classes. Their similarities were analyzed with CoLo, a tool to evaluate the colocalization of transcription factors (TFs) with multiple ChIP-seq peak-call data. Advantages of CoLo are:

(**a**) it compensates for biases derived from different experimental conditions.  
(**b**) it adjusts the difference of the peak numbers and distributions coming from innate characteristics of the TFs.

The function (**a**) is programed so that MACS2 scores in each BED4 file were fitted to a Gaussian distribution, dividing the BED4 files into three groups:

  - **H** (High binding; Z-score > 0.5)
  - **M** (Middle binding; -0.5 ≤ Z-score ≤ 0.5)
  - **L** (Low binding; Z-score < -0.5)

These three groups are used as independent data to evaluate similarity through the function (**b**). Thus, CoLo evaluates the similarity of two SRXs (e.g., SRX\_1 and SRX\_2) with nine combinations:  
```
[H/M/L of SRX_1] x [H/M/L of SRX_2]
```
Eventually, a set of nine Boolean results (similar or not) is returned to indicate the similarity of SRX\_1 and SRX\_2.

###Methods

1. Peak-call data: Same as (**5.1**).
2. STRING library: Same as (**5.2**).
3. Processing:  
  Peak-call data in identical cell-type classes were processed through CoLo. The scores between the two BED files were calculated by multiplication of the combination of the H (= 3), M (= 2), or L (= 1) as follows:


  |SRX_1|SRX_2|Scores|
  |:---:|:---:|:----:|
  |H    |H    |9     |
  |H    |M    |6     |
  |H    |L    |3     |
  |M    |H    |6     |
  |M    |M    |4     |
  |M    |L    |2     |
  |L    |H    |3     |
  |L    |M    |2     |
  |L    |L    |1     |

  If multiple H/M/L combinations were returned from SRX_1 and SRX_2, the highest score was adopted. The scores (1 to 9) were colored in blue, green to red, and gray if all nine H/M/L combinations were false  (see [example][coloSample]). The ‘Average’ column on the far left of the table shows the means of the CoLo scores in the same row. The ‘STRING’ column on the far right indicates the STRING scores for the protein-protein interaction (**6.2**). For more detail, protein-protein pairs in [protein.actions.v10.txt.gz][STRING_DL] file were extracted if meeting all the following conditions:

  - 1st column (item\_id\_a) == query antigen
  - 2nd column (item\_id\_b) == co-association partner
  - 3rd column (mode) == "binding"


<a name="virtual_chip_doc"></a>
## 7. in silico ChIP
###Introduction
ChIP-Atlas **in silico ChIP** accepts users’ data in the following three formats:

- Genomic regions in BED format (to search proteins bound to the regions)
- Sequence motif (to search proteins bound to the motif)
- Gene list (to search proteins bound to the genes)

In addition, the following analyses are possible by specifying the data for comparison on the [submission form][insilicoChIP] of **in silico ChIP**:

|Data in panel 4.|Data in panel 5.       |Aims and analyses                                                   |
|-------|-------------------|--------------------------------------------------------------------|
|BED    |Random permutation |Proteins bound to BED intervals more often than by chance.          |
|BED    |BED                |Proteins differentially bound between the two sets of BED intervals.|
|Motif  |Random permutation |Proteins bound to a sequence motif more often than by chance.                |
|Motif  |Motif              |Proteins differentially bound between the two motifs.               |
|Genes  |RefSeq coding genes|Proteins bound to genes more often than other RefSeq genes.         |
|Genes  |Genes              |Proteins differentially bound between the two sets of gene lists.    |

###Requirements and acceptable data

- Reference peak-call data (upper panels (**1** to **3**) of the [submission form][insilicoChIP]):  
Comprehensive peak-call data as described above (**4. Peak browser**). The result will be returned more quickly if the classes of antigens and cell-types are specified.
- BED (lower panels  (**4** and **5**) of the [submission form][insilicoChIP]):  
[UCSC BED format][UCSC_BED], minimally requiring three tab-delimited columns describing chromosome, and starting and ending positions.

  ```html
  chr1<tab>1435385<tab>1436458
  chrX<tab>4634643<tab>4635798
  ```

  A header and column 4 or later can be included, but they are ignored for the analysis. BE CAREFUL that only BED files in the following genome assemblies are acceptable:
  
  - hg19 (*H. sapiens*)
  - mm9 (*M. musculus*)
  - dm3 (*D. melanogaster*)
  - ce10 (*C. elegans*)
  - sacCer3 (*S. cerevisiae*)
  
  If the BED file is in other genome assembly, convert it to a suitable one with [UCSC liftOver tool][liftOver].
  
- Motif (lower panels  (**4** and **5**) of the [submission form][insilicoChIP]):   
A sequence motif described in [IUPAC nucleic acid notation][IUPAC]. In addition to normal codes (ATGC), ambiguity codes are also acceptable (WSMKRYBDHVN).
- Gene list (lower panels  (**4** and **5**) of the [submission form][insilicoChIP]):   
Gene symbols must be entered according to following nomenclatures:
    
    * [HGNC][HGNC] (*H. sapiens*)  
    * [MGI][MGI] (*M. musculus*)
    * [FlyBase][FlyBase] (*D. melanogaster*)
    * [WormBase][WormBase] (*C. elegans*)
    * [SGD][SGD] (*S. cerevisiae*)

  (e.g., OCT3/4 → POU5F1; p53 → TP53)  
  <br>
If the gene lists are described using any other format (e.g., Gene IDs in Refseq or Emsemble format), use a batch conversion tool such as [DAVID][DAVID] (Convert into OFFICIAL\_GENE\_SYMBOL with Gene ID Conversion Tool).

###Methods

1. Submitted data are converted to BED files depending on the data types.

  - **BED**  
    Submitted BED files are used only for further processing. If ‘Random permutation’ is set for the comparison, the submitted BED intervals are permuted on a random chromosome at a random position for specified times with `bedtools shuffle` command ([bedtools][bedtools]; ver 2.17.0).
  - **Motif**  
    Genomic locations perfectly matching to submitted sequence are searched by [Bowtie][bowtie1] (ver 0.12.8) and converted to BED format. If ‘Random permutation’ is set for the comparison, the BED is used for random permutation as described above.
  - **Gene list**  
    Unique TSSs of submitted genes are defined with xxxCanonical.txt.gz* library distributed from [UCSC FTP site][UCSC_FTP].  
    \* xxx is a placeholder for:

     - “known” (*H. sapiens* and *M. musculus*)
     - “flyBase” (*D. melanogaster*)
     - “sanger” (*C. elegans*)
     - “sgd” (*S. cerevisiae*)



      The locations of TSSs are converted to BED format with the addition of widths specified in ‘Distance range from TSS’ on the [submission form][insilicoChIP]. If ‘RefSeq coding gene’ is set for the comparison, RefSeq coding genes excluding those in submitted list are processed to BED format as mentioned above.

2. The overlaps between the BED (originated from panels **4** and **5** of the [submission form][insilicoChIP]) and reference peak-call data (specified on upper panels **1** to **3** of the [submission form][insilicoChIP]) are counted with `bedtools intersect` command ([BedTools2][bedtools]; ver 2.23.0).
3. *P*-values are calculated with two-tailed Fisher’s exact probability test (see [example][insilicoChIPsample]). The null hypothesis is that the intersection of reference peaks with submitted data in panel **4** occurs in the same proportion to those with data in pannel **5** of the [submission form][insilicoChIP]. *Q*-values are calculated with the Benjamini & Hochberg method.
4. Fold enrichment is calculated by (column 6) / (column 7) of of the same row. If the ratio > 1, the rightmost column is ‘TRUE’, meaning that the proteins from column 3 binds to the data of panel **4** in a greater proportion than to those of panel **5** specified in the [submission form][insilicoChIP].


<a name="downloads_doc"></a>
## 8. Downloads
###Data for each SRX
All ChIP-seq experiments recorded in ChIP-Atlas are described in **experimentList.tab** ([Download] [experimentList], [Table schema](#experimentList_schema))  

- **BigWig**  
  _Download URL_:  
  <a>http://dbarchive.biosciencedbc.jp</a>/kyushu-u/**Genome**/eachData/bw/**Experimental_ID**.bw  

  _Example_:  
  <a>http://dbarchive.biosciencedbc.jp</a>/kyushu-u/**hg19**/eachData/bw/**SRX097088**.bw
  
- **Peak-call (BED)**  
  _Download URL_:  
  <a>http://dbarchive.biosciencedbc.jp</a>/kyushu-u/**Genome**/eachData/bed**Threshold**/**Experimental_ID**.**Threshold**.bed  
  (**Threshold** = 05, 10, or 20)  
  
  _Example_:  
  <a>http://dbarchive.biosciencedbc.jp</a>/kyushu-u/**hg19**/eachData/bed**05**/**SRX097088**.**05**.bed  
  (Peak-call data of SRX097088 with _q_-value < 1E-05.)
  
- **Peak-call (BigBed)**  
  _Download URL_:  
  <a>http://dbarchive.biosciencedbc.jp</a>/kyushu-u/**Genome**/eachData/bb**Threshold**/**Experimental_ID**.**Threshold**.bb  
  (**Threshold** = 05, 10, or 20)  
  
  _Example_:  
  <a>http://dbarchive.biosciencedbc.jp</a>/kyushu-u/**hg19**/eachData/bb**05**/**SRX097088**.**05**.bb  
  (Peak-call data of SRX097088 with _q_-value < 1E-05.)

<br />
###Assembled Peak-call data used in “Peak Browser”
_Download URL_:  
  <a>http://dbarchive.biosciencedbc.jp</a>/kyushu-u/**Genome**/assembled/**File_name**.bed  
  (**Genome** and **File_name** are listed in **fileList.tab** \[[Download] [fileList], [Table schema](#fileList_schema)\])  
  
_Example_:  
  <a>http://dbarchive.biosciencedbc.jp</a>/kyushu-u/**hg19**/assembled/**Oth.ALL.05.GATA2.AllCell**.bed  
  (All peak-call data of GATA2 in all cell types with _q_-value < 1E-05.)

<br />
###Analyzed data used in “Target Genes”
_Download URL_:  
  <a>http://dbarchive.biosciencedbc.jp</a>/kyushu-u/**Genome**/target/**Protein**.**Distance**.tsv  
  (**Protein**s are listed in **analysisList.tab** \[[Download] [analysisList], [Table schema](#analysisList_schema)\])  
  (**Distance** = 1, 5, or 10, indicating the distance [kb] from TSS.)  
  
_Example_:  
  <a>http://dbarchive.biosciencedbc.jp</a>/kyushu-u/**hg19**/target/**POU5F1**.**5**.tsv  
  (TSV file describing the genes bound by POU5F1 at TSS ± 5 kb.)

<br />
###Analyzed data used in “Colocalization”
_Download URL_:  
  <a>http://dbarchive.biosciencedbc.jp</a>/kyushu-u/**Genome**/colo/**Protein**.**Cell\_type\_class**.tsv  
  (**Protein** and **Cell\_type\_class** are listed in **analysisList.tab** \[[Download] [analysisList], [Table schema](#analysisList_schema)\])  
  
_Example_:  
  <a>http://dbarchive.biosciencedbc.jp</a>/kyushu-u/**hg19**/colo/**POU5F1**.**Pluripotent\_stem\_cell**.tsv  
  (TSV file describing the proteins colocalizing with POU5F1 in Pluripotent` `stem` `cell.)  
  (Spaces ` ` in the name of cell type class must be replaced with underscores `_`.)

<br />
###Tables summarizing metadata and files  
<a name="experimentList_schema"></a>

- **experimentList.tab** ([Download] [experimentList])  
All ChIP-seq experiments recorded in ChIP-Atlas.

| Column     | Description                             | Example   |
|------------|-----------------------------------------|-----------|
| 1   | Experimental ID (SRX, ERX, DRX)         | SRX097088     |
| 2   | Genome assembly                                   | hg19      |
| 3   | Antigen class                                     | TFs and others      |
| 4   | Antigen                         | GATA2 |
| 5   | Cell type class  | Blood       |
| 6   | Cell type                                       | K-562 |
| 7   | Cell type description                      | Primary Tissue=Blood\|Tissue Diagnosis=Leukemia Chronic Myelogenous      |
| 8   | Processing logs (# of reads, % mapped, % duplicates, # of peaks [_q_ < 1E-05])                       | 30180878,82.3,42.1,6691      |
| 9 | Title                              | GSM722415: GATA2 K562bmp r1 110325 3  |
| 10- | Meta data submitted by authors                              | source_name=GATA2 ChIP-seq K562 BMP  |
|  |                               | cell line=K562  |
|  |                               | chip antibody=GATA2  |
|  |                               | antibody catalog number=Santa Cruz SC-9008  |
<br />
<a name="fileList_schema"></a>

- **fileList.tab** ([Download] [fileList])  
All assembled peak-call data used in Peak Browser.

| Column     | Description                             | Example   |
|------------|-----------------------------------------|-----------|
| 1   | File name         | Oth.ALL.05.GATA2.AllCell     |
| 2   | Genome assembly                                   | hg19      |
| 3   | Antigen class                                     | TFs and others      |
| 4   | Antigen                         | GATA2 |
| 5   | Cell type class  | All cell types       |
| 6   | Cell type                                       | - |
| 7   | Threshold                      | 05 (indicating _q_-value < 1E-05)     |
| 8   | Experimental IDs included | SRX070877,SRX150427,SRX092303,SRX070876,SRX150668,...|
  
<br />
<a name="analysisList_schema"></a>

- **analysisList.tab** ([Download] [analysisList])  
All proteins shown in “Target Genes” and “Colocalization”.

| Column     | Description                             | Example   |
|------------|-----------------------------------------|-----------|
| 1   | Antigen         | POU5F1     |
| 2   | Cell type class in Colocalization | Epidermis,Pluripotent stem cell      |
| 3   | Recorded (+) or not (-) in Target Genes                                     | +      |
| 4   | Genome assembly                                   | hg19      |
  
<br />
<a name="antigenList_schema"></a>

- **antigenList.tab** ([Download] [antigenList])  
All antigens recorded in ChIP-Atlas.

| Column     | Description                             | Example   |
|------------|-----------------------------------------|-----------|
| 1   | Genome assembly         | hg19     |
| 2   | Antigen class                                     | TFs and others      |
| 3   | Antigen                         | POU5F1 |
| 4   | Number of experiments                                   | 24      |
| 5   | Experimental IDs included | SRX011571,SRX011572,SRX017276,SRX021069,SRX021070,...|

![][antigenNumber]

<br />
<a name="celltypeList_schema"></a>

- **celltypeList.tab** ([Download] [celltypeList])  
All cell types recorded in ChIP-Atlas.

| Column     | Description                             | Example   |
|------------|-----------------------------------------|-----------|
| 1   | Genome assembly         | hg19     |
| 2   | Cell type class  | Prostate       |
| 3   | Cell type                                       | VCaP |
| 4   | Number of experiments                                   | 185      |
| 5   | Experimental IDs included | SRX020917,SRX020918,SRX020919,SRX020920,SRX020921,...|

![][cellTypeNumber]

<!-- Links to files -->
[dataNumber]: http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/allDataNumber_20160526.png "Data numbers"
[antigenNumber]: http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/antigenNumber_20160526.png "Antigen classes"
[cellTypeNumber]: http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/cellTypeNumber_20160526.png "Cell type classes"

[flowchart]: http://devbio.med.kyushu-u.ac.jp/chipatlas/img/flowchart.png "Flow chart"
[ag_attributes]: http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/ag_attributes.txt
[ct_attributes]: http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/ct_attributes.txt
[antigenList]: http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/antigenList.tab
[celltypeList]: http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/celltypeList.tab
[experimentList]: http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/experimentList.tab
[fileList]: http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/fileList.tab
[analysisList]: http://dbarchive.biosciencedbc.jp/kyushu-u/metadata/analysisList.tab

<!-- Links to external web sites -->
[NCBI]: http://www.ncbi.nlm.nih.gov/
[DDBJ]: http://www.ddbj.nig.ac.jp/index-e.html
[ENA]: http://www.ebi.ac.uk/ena
[SRX]: http://www.ncbi.nlm.nih.gov/books/NBK56913/
[NCBImeta]: http://ftp.ncbi.nlm.nih.gov/sra/reports/Metadata/
[SraToolKit]: http://www.ncbi.nlm.nih.gov/Traces/sra/sra.cgi?view=software
[bowtie2]: http://bowtie-bio.sourceforge.net/bowtie2/index.shtml
[bowtie1]: http://bowtie-bio.sourceforge.net/index.shtml
[samtools]: http://samtools.sourceforge.net
[bedtools]: http://bedtools.readthedocs.org/en/latest/
[UCSCtools]: http://hgdownload.cse.ucsc.edu/admin/exe/
[MACS2]: https://github.com/taoliu/MACS/
[PMID_15702071]: http://www.ncbi.nlm.nih.gov/pubmed/15702071
[HGNC]: http://www.genenames.org
[MGI]: http://www.informatics.jax.org
[FlyBase]: http://flybase.org
[WormBase]: https://www.wormbase.org
[SGD]: http://www.yeastgenome.org
[PMID_25877200]: http://www.ncbi.nlm.nih.gov/pubmed/25877200
[ATCC]: http://www.atcc.org
[MeSH]: http://www.ncbi.nlm.nih.gov/mesh
[UCSC_FTP]: http://hgdownload.cse.ucsc.edu/goldenPath
[STRING]: http://string-db.org
[STRING_DL]: http://string.embl.de/newstring_cgi/show_download_page.pl
[UCSC_BED]: https://genome.ucsc.edu/FAQ/FAQformat.html#format1
[liftOver]: https://genome.ucsc.edu/cgi-bin/hgLiftOver
[IUPAC]: https://en.wikipedia.org/wiki/Nucleic_acid_notation
[DAVID]: https://david.ncifcrf.gov
[tgSample]: http://dbarchive.biosciencedbc.jp/kyushu-u/hg19/target/POU5F1.5.html
[coloSample]: http://dbarchive.biosciencedbc.jp/kyushu-u/hg19/colo/NANOG.Pluripotent_stem_cell.html
[insilicoChIP]: http://chip-atlas.org/in_silico_chip
[insilicoChIPsample]: http://dbarchive.biosciencedbc.jp/kyushu-u/sample/insilicoChIP_result_example.html