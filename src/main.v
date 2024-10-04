module main

import encoding.csv
import os
import log
import strings
import strconv
import time

struct TIME {
	name string
	col  int
mut:
	prev  i64
	delta i64
}

struct PROBE {
	name      string
	value_col int
	time_col  int
mut:
	min     f64
	min_loc string
	max     f64
	max_loc string
}

fn main() {
	log.set_level(.info)
	if os.args.len == 1 {
		log.error('jangan lupa kasih path ke file csv sebagai param nya.\ncontoh:\n${os.args[0]} file_csv_nya.csv\nthanks.')
		return
	}

	data := load_csv(os.args[1]) or {
		log.error('${err}')
		return
	}

	mut ph := new_probe('PH', data[0])
	mut cod := new_probe('COD', data[0])
	mut tss := new_probe('TSS', data[0])
	mut nh3n := new_probe('NH3N', data[0])
	mut tim := new_time('WAKTU', data[0])

	mut data_double := []string{}
	mut data_bolong := []string{}

	for i, e in data[1..] {
		tmp := time.parse_format(e[tim.col], 'DD/MM/YYYY, HH:mm') or {
			log.error('waktu tidak ditemukan')
			return
		}

		ph.find_min_max(e)
		cod.find_min_max(e)
		tss.find_min_max(e)
		nh3n.find_min_max(e)

		if i == 0 {
			tim.prev = tmp.unix()
			continue
		} else {
			tim.delta = tmp.unix() - tim.prev
			tim.prev = tmp.unix()
		}

		if tim.delta == 0 {
			s := e[tim.col]
			data_double << s
		} else if tim.delta > 120 {
			s := e[tim.col] + ' len: ' + ((tim.delta / 120) - 1).str()
			data_bolong << s
		}
	}

	println('data bolong total: ${data_bolong.len}')
	for _, e in data_bolong {
		println(e)
	}

	println('data double total: ${data_double.len}')
	for _, e in data_double {
		println(e)
	}
	println('\nprobe summary:')
	ph.print()
	cod.print()
	tss.print()
	nh3n.print()
}

fn find_col_index(header []string, find string) ?int {
	for i, e in header {
		if strings.dice_coefficient(e.to_upper(), find) > 0.0 {
			return i
		}
	}
	return none
}

fn new_time(name string, header []string) TIME {
	return TIME{
		name: 'TIME'
		col:  find_col_index(header, name) or {
			log.error('header tidak di temukan')
			exit(-1)
		}
	}
}

fn load_csv(path string) ![][]string {
	csv_file := os.read_file(path) or { return err }

	print('file: ${path}\n')

	mut csv_reader := csv.new_reader(csv_file, csv.ReaderConfig{ delimiter: `;` })
	mut csv_data := [][]string{}
	for {
		row := csv_reader.read() or { break }
		csv_data << row
	}
	return csv_data
}

fn new_probe(name string, header []string) PROBE {
	return PROBE{
		name:      name
		value_col: find_col_index(header, name) or {
			log.error('header tidak di temukan')
			exit(-1)
		}
		time_col:  find_col_index(header, 'WAKTU') or {
			log.error('header tidak di temukan')
			exit(-1)
		}
		min:       99999.9
	}
}

fn (mut p PROBE) find_min_max(d []string) {
	tmp := strconv.atof64(d[p.value_col]) or { -1.0 }
	if tmp < p.min {
		p.min = tmp
		p.min_loc = d[p.time_col]
	}
	if tmp > p.max {
		p.max = tmp
		p.max_loc = d[p.time_col]
	}
}

fn (p &PROBE) print() {
	print('${p.name}\nmin :\t${p.min}\ttime: ${p.min_loc}\nmax :\t${p.max}\ttime: ${p.max_loc}\n')
}
